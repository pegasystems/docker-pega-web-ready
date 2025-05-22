<%
    response.setStatus(302);
    response.sendRedirect("/{{ .Env.PEGA_APP_CONTEXT_PATH }}/");
    response.setHeader( "Connection", "close" );
%>