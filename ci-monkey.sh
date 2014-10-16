#!/bin/bash
set -ex
group=$1
shortUrl=$2
url=$3
apiUrl=$4
token=$5
jenkins=$6
user1=$7
user2=$8
branch=$9
startingLocation=$PWD
#get list of repos
curl -s -k -H "Authorization: token $token" $url/users/$group/repos?per_page=100 | grep \"name\": | sed s/\"name\":\ \"//g | sed s/\",//g > tmp
while read repo; do
  location=$group-$repo
  #iterate through repos looking for those without a jenkins folder
  j=`curl -s -k -H "Authorization: token $token" $url/repos/$group/$repo/contents/jenkins | { grep \"message\":\ \"Not\ Found\" || true; }`
  if [[ -n $j ]]; then
    git clone git@$shortUrl:$group/$repo $location
    cd $location
    #get default branch and checkout it out
    default_branch=`curl -s -k -H "Authorization: token $token" $url/repos/$group/$repo | grep -m1 '"default_branch":' | sed s/'"default_branch": "'//g | sed s/'",'//g`
    git checkout $default_branch
    #make jenkins folder and copy template yaml file in replacing @repo@ with the repo name
    mkdir jenkins
    #if scala project use the scala template
    if [ -a build.sbt ]; then
      template="../ci-monkey/scala.yaml"
      script="../ci-monkey/scala.sh"
    #if a cookbook use the cookbook template
    elif [ -a metadata.rb ]; then
      template="../ci-monkey/cookbook.yaml"
      script="../ci-monkey/cookbook.sh"
    #if grunt build use the grunt template
    elif [ -a Gruntfile.js ]; then
      template="../ci-monkey/grunt.yaml"
      script="../ci-monkey/grunt.sh"
    #If Rakefile then its a gis build
    elif [ -a Rakefile ]; then
      template="../ci-monkey/gis.yaml"
      script="../ci-monkey/gis.sh"
    #else laydown generic template
    else
      template="../ci-monkey/generic.yaml"
      script="../ci-monkey/generic.sh"
    fi
    sed s/@repo@/$repo/g $template > jenkins/$repo.yaml
    sed -i s/@group@/$group/g jenkins/$repo.yaml
    sed -i s#@url@#$shortUrl#g jenkins/$repo.yaml
    sed -i s#@apiUrl@#$apiUrl#g jenkins/$repo.yaml
    sed -i s/@user1@/$user1/g jenkins/$repo.yaml
    sed -i s/@user2@/$user2/g jenkins/$repo.yaml
    sed -i s/@token@/$token/g jenkins/$repo.yaml
    sed -i s/@branch@/$branch/g jenkins/$repo.yaml
    #create jenkins jobs
    curl "http://nexus2.drillinginfo.com:8081/nexus/service/local/artifact/maven/redirect?r=releases&g=com.drillinginfo.cm&a=jjb-templates&p=yaml&v=RELEASE" -Lo jenkins/jjb-templates-latest.yaml
    curl "http://nexus2.drillinginfo.com:8081/nexus/service/local/artifact/maven/redirect?r=releases&g=com.drillinginfo.cm&a=jjb-macros&p=yaml&v=RELEASE" -Lo jenkins/jjb-macros-latest.yaml
    jenkins-jobs update jenkins
    #run script to further customize repo
    . ./$script
    changeRepo
    #Set IFS to blank to preserve spacing
    IFS=''
    #add build badge.  If readme doesn't exist create it with build badge, if it does exist prepend the build badge
    if [[ -e README.md ]]; then
      readme=README.md
    fi
    if [[ -e README ]]; then
      readme=README
    fi
    if [[ -e README.md || -e README ]]; then
      echo "[![Build Status](http://$jenkins/buildStatus/icon?job=$repo-build)](http://$jenkins/job/$repo-build/)">README.new
      echo "">>README.new
      while read line; do
        echo $line>>README.new
      done < $readme
      mv README.new README.md
    else
      echo "[![Build Status](http://$jenkins/buildStatus/icon?job=$repo-build)](http://$jenkins/job/$repo-build/)">README.md
      echo "">>README.md
    fi
    #Set IFS back to a space
    IFS=' '
    #add changes to repo and push to default branch
    git add jenkins/$repo.yaml README.md
    #add changes made in script
    addChanges
    git commit -m "Adding Jenkins Jobs and build badge"
    git push origin $default_branch
    #change back to top level folder
    cd ../
    #create github webhook
    curl -k -H "Authorization: token $token" -d "
      {
        \"name\": \"web\",
        \"active\": true,
        \"events\": [
          \"push\" ],
        \"config\": {
          \"url\": \"http://$jenkins/github-webhook/\"
        }
      }" -X POST $url/repos/$group/$repo/hooks
  cd $startingLocation
  rm -r $location
  fi
done < tmp
