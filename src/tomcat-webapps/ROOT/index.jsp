<%
    String path = request.getServletPath();
    if ("/index.jsp".equals(path)) {
      response.setStatus(302);
      response.sendRedirect("/{{ .Env.PEGA_APP_CONTEXT_PATH }}/");
    } else {
      response.setStatus(404);
    }
    response.setHeader( "Connection", "close" );
%>