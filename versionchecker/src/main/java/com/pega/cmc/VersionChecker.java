package com.pega.cmc;

import java.sql.*;
import java.util.Properties;

public class VersionChecker {
    static final String ENV_JDBC_DRIVER_CLASS = "JDBC_CLASS";
    static final String ENV_JDBC_URL          = "JDBC_URL";
    static final String ENV_JDBC_USER         = "SECRET_DB_USERNAME";
    static final String ENV_JDBC_PASSWORD     = "SECRET_DB_PASSWORD";
    static final String ENV_JDBC_CONN_PROPS   = "JDBC_CONNECTION_PROPERTIES";
    static final String ENV_RULE_SCHEMA_NAME  = "RULES_SCHEMA";

    static final String PROP_USER = "user";
    static final String PROP_PASSWORD = "password";

    private String jdbcDriverClass;
    private String jdbcUrl;
    private String jdbcUser;
    private String jdbcPassword;
    private String jdbcConnectionProperties;

    private String rulesSchemaName;

    private VersionChecker() {}

    void setJdbcDriverClass(String jdbcDriverClass) {
        this.jdbcDriverClass = jdbcDriverClass;
    }

    void setJdbcUrl(String jdbcUrl) {
        this.jdbcUrl = jdbcUrl;
    }

    void setJdbcUser(String jdbcUser) {
        this.jdbcUser = jdbcUser;
    }

    void setJdbcPassword(String jdbcPassword) {
        this.jdbcPassword = jdbcPassword;
    }

    void setJdbcConnectionProperties(String jdbcConnectionProperties) {
        this.jdbcConnectionProperties = jdbcConnectionProperties;
    }

    void setRulesSchemaName(String rulesSchemaName) {
        this.rulesSchemaName = rulesSchemaName;
    }

    void loadDriver() {
        try {
            Driver driver = (Driver) Class.forName(jdbcDriverClass, true, this.getClass().getClassLoader()).getDeclaredConstructor().newInstance();
            DriverManager.registerDriver(driver);
        } catch(Exception e) {
            throw new VersionCheckerException("Encountered exception while trying to load '" + jdbcDriverClass + "' driver class.", e);
        }
    }

    Properties parsePropertyString() {
        Properties props = new Properties();

        if (jdbcConnectionProperties!=null && !jdbcConnectionProperties.isEmpty()) {
            String[] nv = jdbcConnectionProperties.split(";");
            for (String prop: nv) {
                if (!prop.contains("=")) {
                    throw new VersionCheckerException("Connection property '" + prop + "' is formatted incorrectly ");
                }
                String[] token =  prop.split("=", 2);
                props.put(token[0], token[1]);
            }
        }
        return props;
    }

    void addCredentialProperties(Properties props) {
        if (jdbcUser!=null && !jdbcUser.isEmpty()) {
            props.put(PROP_USER, jdbcUser);
        }
        if (jdbcPassword!=null && !jdbcPassword.isEmpty()) {
            props.put(PROP_PASSWORD, jdbcPassword);
        }
    }

    private Connection getConnection(Properties props) throws SQLException {
        return DriverManager.getConnection(jdbcUrl, props);
    }

    String getQuery() {
        return "select max(pyrulesetversionid) from " +
                rulesSchemaName +
                ".pr4_rule_ruleset where pxObjClass='Rule-RuleSet-Version' and pyrulesetname='Pega-RULES'";
    }

    String performQuery(Properties props) {
        try {
            try (Connection c = getConnection(props);
                 PreparedStatement ps = c.prepareStatement(getQuery());
                 ResultSet rs = ps.executeQuery();) {
                rs.next();
                return rs.getString(1);
            }
        } catch (SQLException e) {
            throw new VersionCheckerException("Encountered exception while querying for Pega version: ", e);
        }
    }

    public String checkVersion() {
        loadDriver();
        Properties props = parsePropertyString();
        addCredentialProperties(props);
        return performQuery(props);
    }

    public static VersionChecker createVersionChecker(EnvHelper env) {
        VersionChecker versionChecker = new VersionChecker();

        versionChecker.setJdbcDriverClass(env.getEnvVar(ENV_JDBC_DRIVER_CLASS));
        versionChecker.setJdbcUrl(env.getEnvVar(ENV_JDBC_URL));
        versionChecker.setJdbcUser(env.getEnvVar(ENV_JDBC_USER));
        versionChecker.setJdbcPassword(env.getEnvVar(ENV_JDBC_PASSWORD));
        versionChecker.setJdbcConnectionProperties(env.getEnvVar(ENV_JDBC_CONN_PROPS));
        versionChecker.setRulesSchemaName(env.getEnvVar(ENV_RULE_SCHEMA_NAME));

        return versionChecker;
    }

    public static void main(String[] args) {
        VersionChecker versionChecker = createVersionChecker(new SystemEnvHelper());
        try {
            System.out.println(versionChecker.checkVersion());
        } catch (RuntimeException e) {
            e.printStackTrace(System.err);
            System.err.flush();
            System.exit(1);
        }
    }
}
