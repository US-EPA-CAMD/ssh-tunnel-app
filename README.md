# SSH Tunnel Application

[![License](https://img.shields.io/github/license/US-EPA-CAMD/ssh-tunnel-app)](https://github.com/US-EPA-CAMD/ssh-tunnel-app/blob/develop/LICENSE)
[![Develop CI/CD](https://github.com/US-EPA-CAMD/ssh-tunnel-app/workflows/Develop%20Branch%20Workflow/badge.svg)](https://github.com/US-EPA-CAMD/ssh-tunnel-app/actions)
[![Release CI/CD](https://github.com/US-EPA-CAMD/ssh-tunnel-app/workflows/Release%20Branch%20Workflow/badge.svg)](https://github.com/US-EPA-CAMD/ssh-tunnel-app/actions)
![Issues](https://img.shields.io/github/issues/US-EPA-CAMD/ssh-tunnel-app)
![Forks](https://img.shields.io/github/forks/US-EPA-CAMD/ssh-tunnel-app)
![Stars](https://img.shields.io/github/stars/US-EPA-CAMD/ssh-tunnel-app)

## Description

SSH tunnel application for cloud.gov database connections. Dummy application bound to database services that provide a dedicated connection to the EASEY Database. The application leverages the [apt-buildpack](https://github.com/cloudfoundry/apt-buildpack) to incorporate PostgreSQL client tools within the app’s container. **Note that the apt-buildpack is considered experimental and is not supported by Cloud.gov. Using this in a production setting would require you to address the security controls.** This setup enables the execution of [Cloud Foundry Tasks](https://docs.cloudfoundry.org/devguide/using-tasks.html), allowing for the implementation of various PostgreSQL commands such as `pg_dump`, `pg_restore`, and `psql`. Importantly, each `aws-rds` service instance bound to the application manages its credentials automatically, eliminating the need to manually enter passwords when executing commands.

## Getting Started

Follow these [instructions](https://github.com/US-EPA-CAMD/devops/blob/master/GETTING-STARTED.md) to get the project up and running correctly.

## Installing

1. Open a terminal and navigate to the directory where you wish to store the repository.
2. Clone the repository using one of the following git cli commands or using your favorit Git management software<br>
   **Using SSH**
   ```
   $ git clone git@github.com:US-EPA-CAMD/ssh-tunnel-app.git
   ```
   **Using HTTPS**
   ```
   $ git clone https://github.com/US-EPA-CAMD/ssh-tunnel-app.git
   ```
3. Navigate to the projects root directory
   ```
   $ cd ssh-tunnel-app
   ```

## Usage as a Task Runner

Modify the manifest.yml file or use the `cf` command line tool to bind the aws-rds postgres instance to the app. Push the app to cloud foundry.

Run a task with the Cloud Foundry `run-task` command. The desired shell command to execute should be passed to the `--command` argument.

```bash
cf run-task ssh-tunnel --command 'psql <database> -c "\pset tuples_only on" -c "SELECT version()" -c "\pset tuples_only off" -h <host> -p <port> -U <user>'
```

You can check the status of the task using the `cf tasks` command.

```bash
cf tasks ssh-tunnel

Getting tasks for app ssh-tunnel in org my-org  / space my-space as user@name.com...

id   name       state       start time                      command
5    bfa9cef9   SUCCEEDED   Wed, 22 Mar 2023 21:07:56 UTC   psql <database> -c "\pset tuples_only on" -c "select version()" -c "\pset tuples_only off" -h <host> -p <port> -U <user>
```

You can view the logs for the running task using the `cf logs` command.

```bash
cf logs ssh-tunnel --recent

Retrieving logs for app ssh-tunnel in org my-org / space my-space as

2020-03-22T21:07:56.00-0400 [APP/TASK/bfa9cef9/0] OUT 2020-03-23 01:07:56,000 INFO: PostgreSQL 15.7 (Ubuntu 14.13-0ubuntu0.22.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
...
```

## PostgreSQL client tools

The client tools are installed in the container using the apt-buildpack. You may need to modify the apt.yml file to install the correct version of the client tools for your target database. If you do this you will need to modify the PATH set in .profile to point to the correct location of the client tools. Without this change, pg_wrapper will try to locate the client tools in the default location in Ubuntu and fail.

## License & Contributing

This project is licensed under the MIT License. We encourage you to read this project’s [License](LICENSE), [Contributing Guidelines](CONTRIBUTING.md), and [Code of Conduct](CODE-OF-CONDUCT.md).

## Disclaimer

The United States Environmental Protection Agency (EPA) GitHub project code is provided on an "as is" basis and the user assumes responsibility for its use. EPA has relinquished control of the information and no longer has responsibility to protect the integrity , confidentiality, or availability of the information. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by EPA. The EPA seal and logo shall not be used in any manner to imply endorsement of any commercial product or activity by EPA or the United States Government.
