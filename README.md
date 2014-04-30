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

Future
---
I want this repo to lay down yamls that are much smaller than the current
templates are.  In the future I see this going much like travis-ci where
the build in source is very minimal and just describes a few important
details like what version to build with etc.  This can be accomplished
with making the macros and job templates into external resources that
are downloaded upon the JJB run.  Then when JJB runs it will merge the
macros and templates and the repo-specific yaml into one and create the
jobs appropriately.

Below is the future yaml I have in mind.  It will create three jobs one
for the main build, one for the pull-request build, and one for the JJB
build.  Then it specifies the type of build it is and the macros and
templates pick up from there.
```
- project:
    name: map-widget
    organization: DIGlobal
    jobs:
      - "{name}-build":
          type: "javascript"
      - "{name}-pull-request":
          type: "javascript"
      - "{name}-jjb"
```
