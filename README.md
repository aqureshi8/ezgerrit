# EZ Gerrit Setup

## Github Replication Plugin
1. Create repo on github
1. Update `replication/replication.config`
    * In config header, replace `replace-with-repo-name` with the name of the repo
    * In url, replace `replace-with-username` with the username of the github account that will be used for replication
    * In projects, replace `replace-with-repo-name` with the name of the repo
1. SSH to github in gerrit container
    * `ssh git@github.com`
    * When asked if you want to add a new host, enter `yes`
1. Copy `replication/replication.config` to `${GERRIT_SITE}/etc/replication.config` and `replication.jar` to `${GERRIT_SITE}/plugins/replication.jar`
1. Restart gerrit
1. Replication should start on your next merge