<p><img src="https://storage.googleapis.com/coda-charts/Mina_Icon_Secondary_RGB_Black.png" alt="Mina logo" title="mina" align="left" height="60" /></p>

# Testnet Monitoring & Alerting :fire_engine: Guide

**Table of Contents**
- [Updating Testnet Alerts](#update-testnet-alerts)
    - [Developing alert expressions](#developling)
    - [Testing](#testing)
    - [Deployment](#deployment)
- [Alert Status](#alert-status)
    - [GrafanaCloud Config](#grafancloud-config)
    - [Alertmanager UI](#alertmanager-ui)
    - [PagerDuty](#pagerduty)
- [HowTo](#howto)
    - [Silence Alerts](#silence-alerts)
    - [Update Alert Receivers](#update-alert-receivers)
    - [View Alert Metrics](#view-alert-metrics)

## Updating Testnet Alerts

#### Developing alert expressions

Developing alert expressions consists of using Prometheus's domain-specific [query language](https://prometheus.io/docs/prometheus/latest/querying/basics/) ([examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)) coupled with its alert rules specification [format](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) for devising metric and alerting conditions/rules.

To enable variability when defining these rules, each rule set or group is implemented using *terraform*'s [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) and `(${ ... })` templating mechanisms for including variable substition where appropriate (**note:** variable substitutions are *optional* and provided as defaults - alert rules can be defined completely according to a custom specification).

A standard set of such testnet alert rules based on templates is defined [here](https://github.com/MinaProtocol/mina/blob/develop/automation/terraform/modules/testnet-alerts/templates/testnet-alert-rules.yml.tpl#L6) and should be edited when adding rules to be applied to all testnets.

Generally, when adding or updating alerts:
1. Consult [Grafanacloud's Prometheus Explorer](https://o1testnet.grafana.net/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22grafanacloud-o1testnet-prom%22,%7B%7D%5D) to ensure the metric to alert on is collected by infrastructure's Prometheus instances. If missing, reach out to [#reliability-engineering](https://discord.com/channels/484437221055922177/610580493859160072) for help on getting it added.
1. Apply alerting changes to *testnet-alert-rules.yml.tpl* based on the aforementioned Prometheus query language and alerting rules config.

#### Testing

Testing of testnet alerts currently involves leveraging Grafana's [cortex-tools](https://github.com/grafana/cortex-tools), a toolset developed and maintained by the Grafana community for managing Prometheus/Alertmanager alerting configurations. Specifically, the testing process makes use of `lint` and `check` for ensuring alerting rules defined within *testnet-alert-rules.yml* are both syntactically correct and also meet best practices/standards for maintaining consistency in how rules are expressed and formatted. Both operations can be executed automatically in CI or manually within a developer's local environment.

**Note:** all manual steps are executed in a Docker container/environment to ensure portability and should be run from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory with the *mina* repo.

##### Linting

[lints](https://github.com/grafana/cortex-tools#rules-lint) a testnet alert rules file. The linter's aim is not to verify correctness but just YAML and PromQL expression formatting within the rule file. This command always edits in place, you can use the **dry run flag (-n)** if you'd like to perform a trial run that does not make any changes.

###### automation

Executed by CI's *Lint/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Lint/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file.

###### manual steps

    `terraform apply -target module.o1testnet_alerts.docker_container.lint_rules_config` 

##### Check alerts against recommended [best practices](https://prometheus.io/docs/practices/rules/)

###### automation

Executed by CI's *Lint/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Lint/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file.

###### manual steps

    `terraform apply -target module.o1testnet_alerts.docker_container.check_rules_config`

#### Deployment

Deploying testnet alert rules entails syncing the rendered configuration in source with O(1) Lab's Grafanacloud Prometheus instance rules config found [here](https://o1testnet.grafana.net/a/grafana-alerting-ui-app/?tab=rules&rulessource=grafanacloud-o1testnet-prom). Appropriate AWS access is necessary for authenticating with Grafanacloud and should be similar to, if not the same, as those used for deploying testnets.

###### automation

Executed by CI's *Release/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Release/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file and linting/checking of alerts has succeeded.

###### manual steps

    `terraform apply -target module.o1testnet_alerts.docker_container.sync_alert_rules`

**Note:** operation will sync provisioned alerts with exact match of alert file state (e.g. alerts removed from the alert file will be unprovisioned on Grafanacloud)

## Alert Status

#### GrafanaCloud Config

To view the current testnet alerting rules config or verify that changes were applied correctly following a deployment, visit O(1) Lab's Grafanacloud rules config [site](https://o1testnet.grafana.net/a/grafana-alerting-ui-app/?tab=rules&rulessource=grafanacloud-o1testnet-prom).

**Note:** ensure the datasource is set to `grafanacloud-o1testnet-prom` to access the appropriate ruleset. 

#### Alertmanager UI

Alerting rule violations can also be viewed in Grafanacloud's Alertmanager [UI](https://alertmanager-us-central1.grafana.net/alertmanager/#/alerts). This site provides an overview of all violating rule conditions in addition to rules that have been silenced. 

#### PagerDuty

PagerDuty is O(1) Lab's primary alert receiver and currently services a single [service](https://o1labs.pagerduty.com/service-directory/PY2JUNP) for monitoring Mina testnet deployments. This service receives alert notifications requiring attention from the development team to assist in repairing issues and restoring network health.

For more information, reach out to [#reliability-engineering](https://discord.com/channels/484437221055922177/610580493859160072) on Mina's Discord channel with questions etc.

## HowTo

#### Silence Alerts

* Pagerduty alert suppression: see [guide](https://support.pagerduty.com/docs/event-management#suppressing-alerts)
* Alertmanager alert silencing: create new alerts using either the [Alertmanager](https://alertmanager-us-central1.grafana.net/alertmanager/#/silences/new) or [Grafanacloud](https://o1testnet.grafana.net/a/grafana-alerting-ui-app/?tab=silences&alertmanager=grafanacloud-o1testnet-alertmanager) UI.

##### Creating new silences

When creating new alert silences (from the above link or otherwise), you'll likely want to make use of the AlertManager's `Matchers` construct, which basically consists of a set of key-value pairs used to target the alert to silence. For example, if silencing the "LowFillRate" alert currently firing for testnet *devnet*, you would create a new silence with individual `Matchers` for the alert name and testnet like the following:

###### Matchers example

| Name | Value|
| ------------- | ------------- |
| testnet  | devnet  | 
| alertname  | LowFillRate  |

![Grafanacloud New Silence](https://storage.googleapis.com/shared-artifacts/grafanacloud-new-silence.png)

Note the `Start`, `Duration` and `End` inputs in the UI. Typically only the duration of a silence would be updated though Alertmanager supports specification of start and end times based on internet timing standards [RFC3339](https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14).

**Be sure to set the *Creator* and *Comments* field accordingly to provide insight into the reasoning for the silence and guidelines for following up.**

#### Update Alert Receivers

Alert receivers are reporting endpoints for messaging alert rules which are in violation. Think a *PagerDuty* page, *incident* email, SMS message or Discord notification. A list of available receivers along with their associated configuration documentation can be found [here](https://prometheus.io/docs/alerting/latest/configuration/). All receivers are configured within an *Alertmanager* service's receivers config which sets a series of alerting routes based on `match` and `match_re` (regular expression) qualifiers applied to incoming rule violations received by the service. Currently both PagerDuty and Discord webhook receivers are setup for receiving these rule violations and forwarding to their appropriate destinations and are configured [here](https://github.com/MinaProtocol/mina/blob/develop/automation/terraform/modules/testnet-alerts/templates/testnet-alert-receivers.yml.tpl).

Updates to testnet alert receivers will typically involve 1 or more of the following tasks:
* modify which testnets trigger Pagerduty incidents when alert rule violations occur
* update the Testnet PagerDuty service integration key
* update the Discord webhook integration key

##### Modify testnets which alert to PagerDuty

The list of testnets which trigger PagerDuty incidents when rule violations occur is controlled by a single regular expression defined in the [o1-testnet-alerts](https://github.com/MinaProtocol/mina/blob/develop/automation/terraform/monitoring/o1-testnet-alerts.tf#L17) terraform module config. 

This value can be modified to any regex for capturing testnets by name though should generally be a relatively simple expression (e.g. `"mainnet|qanet|release-net"`) considering the critical nature of the setting and allowing easy identification of which testnets developers will be paged about. 

##### Update Pagerduty Testnet Service Integration Key 

Reach out to *#reliability-engineering* for assistance.

##### Update Discord webhook integration key 

Reach out to *#reliability-engineering* for assistance.

#### Deploy Alert Receiver Updates

To view the current alerting receiver configuration or verify changes following a deployment, visit O(1) Lab's Grafanacloud alertmanager receiver [configuration](https://o1testnet.grafana.net/a/grafana-alerting-ui-app/?tab=config&alertmanager=grafanacloud-o1testnet-alertmanager).

##### Steps

    `terraform apply -target module.o1testnet_alerts.docker_container.update_alert_receivers` from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory.

#### View Alert Metrics

When responding to a PagerDuty incident, you'll likely want to check the Alert's *Annotations:Source* for visualizing the metrics series responsible for the firing alert. This information is contained within each incident page under the `ALERTS : CUSTOM DETAILS` section in the form of a URL which links to Grafancloud's Prometheus explorer.

![PagerDuty Incident Annotations](https://storage.googleapis.com/shared-artifacts/pagerduty-incident-annotations.png)

From here, it's possible to explore the values of the offending metric (along with others) over time for investigating incidents.

![PagerDuty Incident Metric Explorer](https://storage.googleapis.com/shared-artifacts/grafanacloud-incident-metric-explorer.png)
