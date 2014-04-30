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
#get list of repos
curl -s -k -H "Authorization: token $token" $url/users/$group/repos?per_page=100 | grep \"name\": | sed s/\"name\":\ \"//g | sed s/\",//g > tmp
while read repo; do
  #iterate through repos looking for those without a jenkins folder
  j=`curl -s -k -H "Authorization: token $token" $url/repos/$group/$repo/contents/jenkins | { grep \"message\":\ \"Not\ Found\" || true; }`
  if [[ -n $j ]]; then
    git clone git@$shortUrl:$group/$repo
    cd $repo
    #get default branch and checkout it out
    default_branch=`curl -s -k -H "Authorization: token $token" $url/repos/$group/$repo | grep -m1 '"default_branch":' | sed s/'"default_branch": "'//g | sed s/'",'//g`
    git checkout $default_branch
    #make jenkins folder and copy template yaml file in replacing @repo@ with the repo name
    mkdir jenkins
    #if scala project use the scala template
    if [ -a build.sbt ]; then
      template="../scala.yaml"
      script="../scala.sh"
    #if a cookbook use the cookbook template
    elif [ -a metadata.rb ]; then
      template="../cookbook.yaml"
      script="../cookbook.sh"
    #if grunt build use the grunt template
    elif [ -a Gruntfile.js ]; then
      template="../grunt.yaml"
      script="../grunt.sh"
    #else laydown generic template
    else
      template="../generic.yaml"
      script="../generic.sh"
    fi
    cp $template jenkins/$repo.yaml
    sed -i s/@repo@/$repo/g jenkins/$repo.yaml
    sed -i s/@group@/$group/g jenkins/$repo.yaml
    sed -i s/@url@/$shortUrl/g jenkins/$repo.yaml
    sed -i s/@apiUrl@/$apiUrl/g jenkins/$repo.yaml
    sed -i s/@user1@/$user1/g jenkins/$repo.yaml
    sed -i s/@user2@/$user2/g jenkins/$repo.yaml
    sed -i s/@token@/$token/g jenkins/$repo.yaml
    sed -i s/@branch@/$branch/g jenkins/$repo.yaml
    #create jenkins jobs
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
    git add jenkins README.md
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
  fi
done < tmp
