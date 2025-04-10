package com.pega.cmc;

import java.util.Arrays;
import java.util.Optional;

public enum DBType {
    POSTGRES("postgres"),
    MSSQL("mssql"),
    ORACLE("oracledate"),
    DB2LUW("udb"),
    DB2ZOS("db2zos"),
    H2("h2"); //for unit testing

    private String typeDescriptor;

    DBType(String typeDescriptor) {
        this.typeDescriptor = typeDescriptor;
    }

    public String getTypeDescriptor() { return this.typeDescriptor; }

    public static boolean isValid(String typeDescriptor) {
        Optional<DBType> result = getDBType(typeDescriptor);
        return result.isPresent();
    }

    public static Optional<DBType> getDBType(String typeDescriptor) {
        return Arrays.stream(DBType.values())
                .filter(dbType -> dbType.getTypeDescriptor().equals(typeDescriptor))
                .findAny();
    }
}
