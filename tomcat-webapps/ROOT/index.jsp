<%
    String path = request.getServletPath();
    if ("/index.jsp".equals(path)) {
      response.setStatus(302);
      response.sendRedirect("/prweb/");
    } else {
      response.setStatus(404);
    }
    response.setHeader( "Connection", "close" );
%>