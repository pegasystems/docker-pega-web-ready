## Current State of Pega Platform Configuration in pegasystems/pega  

The pegasystems/pega image in conjunction with [Pega Helm Charts](https://github.com/pegasystems/pega-helm-charts) provides multiple ways to configure and customize a Pega deployment

The following table provides an overview of the different configuration files in the deployment and the intended use:

| File Name | Source | Purpose | Customizability |
| ---       | ---    | ---     | ---             |
|prconfig.xml|prweb.war|Base prconfig.xml <br/><br/>*Note: May be overidden by helm deployment* | None |
|prlog4j2.xml|prweb.war|Base prlog4j2.xml <br/><br/>*Note: May be overidden by helm deployment* | None |
|context.xml|pegasystems/tomcat|Base web application context <br/><br/>*Note: May be overidden by helm deployment* | None |
|[prweb.xml](https://github.com/pegasystems/docker-pega-web-ready/blob/master/tomcat-conf/Catalina/localhost/prweb.xml)|docker-pega-web-ready|Recommended Pega platform configuration for Kubernetes <br/><br/>*Note: Parameter settings may be overridden by helm* | Parameter values customizable via environment variables |
|[context.xml.tmpl](https://github.com/pegasystems/docker-pega-web-ready/blob/master/tomcat-conf/context.xml.tmpl)|docker-pega-web-ready|Templatized web application context <br/><br/>*Note: Parameter settings may be overridden by helm*| Parameter values customizable via environment variables |
|[setenv.sh](https://github.com/pegasystems/docker-pega-web-ready/blob/master/tomcat-bin/setenv.sh)|docker-pega-web-ready|Sets up environment for Tomcat startup | Values customizable via environment variables |
