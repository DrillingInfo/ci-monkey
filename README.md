Overview
---
This is a work in progress and can definitely use some work to be more
generic to work with everyone's repos.  Please open issues, or even
better pull requests, to make it work better.

This repo aims to create a 'monkey' that goes around finding repos without
jenkins jobs and giving it to them.  It will try and detect what type of
build is required for the repo and lay down a template for the repo and
then run a script with further customization steps.  The scripts have been
left blank so you can customize them but still track the main script.

The idea behind the ci-monkey is to create a framework where the developer
can start a repo with the framework of choice and push that to github and
the ci-monkey will give him continuous integration and then he just has to
continue writing code.

The ci-monkey uses Jenkins Job Builder to configure the jobs in Jenkins

Usage
---
create a shell file that calls ci-monkey

Example
---
```
#!/bin/bash
group=[github organization]
group2=[github organization2]
shortUrl=[url to github without https or anything]
url=[full path to github api]
apiUrl=[api url to github without https or anything]
token=[github token]
jenkins=[ip or name of jenkins]
user1=[first user with admin privileges to github pull request builds]
user2=[second user with admin privileges to github pull request builds]
branch=[branch to build, leave blank for all branches, can use wildcards]

./ci-monkey.sh $group $shortUrl $url $apiUrl $token $jenkins $user1 $user2 $branch
./ci-monkey.sh $group2 $shortUrl $url $apiUrl $token $jenkins $user1 $user2 $branch
```

Pre-requisites
---
* jenkins job builder

Travis CI for Jenkins
---
The templates for repos now are much smaller and more inline with what travis
ci does, where you only have a few lines in the yaml and the rest is
centralized.  Sample macros and templates files are located in the repository
as jjb-macros-latest.yaml and jjb-templates-latest.yaml.  The yaml files that
go in the repository have been updated to work with the macros and templates.
There are a few tokens that need to be replaced in the macros and templates
files.  They are denoted with square brackets.
