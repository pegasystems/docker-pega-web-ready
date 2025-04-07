package com.pega.cmc;

public class VersionCheckerException extends RuntimeException {

    public VersionCheckerException(String message) {
        super(message);
    }

    public VersionCheckerException(String message, Throwable cause) {
        super(message, cause);
    }
}
