package com.pega.cmc;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.Optional;
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

    private static String outputFile;

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
        if (rulesSchemaName==null || rulesSchemaName.trim().isEmpty()) {
            throw new VersionCheckerException("Rules schema name must be specified");
        }
        if (!isSchemaNameSanitized()) {
            throw new VersionCheckerException("Rules schema name '" + rulesSchemaName + "' is not valid -- please check for illegal characters.");
        }

        return "select max(pyrulesetversionid) from " +
                rulesSchemaName +
                ".pr4_rule_ruleset where pxObjClass='Rule-RuleSet-Version' and pyrulesetname='Pega-RULES'";
    }

    boolean isSchemaNameSanitized() {
        return rulesSchemaName.matches("[a-zA-Z][a-zA-Z0-9_$#]*");
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
        String version = performQuery(props);
        if (version==null || version.isEmpty()) {
            throw new VersionCheckerException("Version check resulted in an empty result.");
        }
        return version;
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
        if (args.length>=1) {
            outputFile = args[0];
        }
        VersionChecker versionChecker = createVersionChecker(new SystemEnvHelper());
        try {
            String version = versionChecker.checkVersion();
            if (outputFile!=null) {
                try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                    fos.write(version.getBytes(StandardCharsets.UTF_8));
                }
            } else {
                System.out.println(version);
            }
        } catch (RuntimeException | IOException e) {
            e.printStackTrace(System.err);
            System.err.flush();
            System.exit(1);
        }
    }
}
