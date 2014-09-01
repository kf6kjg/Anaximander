Partial Class map
 Inherits System.Web.UI.Page

 '* This web page script is licensed as LGPL limited public domain source.
 '* http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License
 '* It is intended for use with the Anaximander map tile processing program running in a Windows server for 
 '* use with InWorldz or OpenSim based grids.
 '* This page is set up as a page in your grid's website and the OpenSim.ini points to it using the 
 '* [SimulatorFeatures], MapImageServerURI = "http://domain/path/map.aspx". Put in your own domain and path to the file.
 '* This page presumes it is in the same location as the /maptiles folder, but that may be changed as long as there is 
 '* a path to that folder accsessible to this page.
 '* Original page created by Bob Curtice, www.GospelLearningCenter.com in .Net 2.0 for Windows OS.
 '* Software is supplied as is.

 Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

  Trace.IsEnabled = False
  If Trace.IsEnabled Then Trace.Warn("Map", "Start Page Load")

  ' Define process unique objects here

  ' Get command line content to parse the image or coordinates sent to this page:
  ' Requests appear to be /map-lvl-x-y-objects.jpg where lvl is the zoom level and x,y are the grid coordinates.
  ' Or x=,y=,z= as get parms, where x, y are grid coordinates and z is the zoom level.
  Dim tRequest, InParm(), x, y, z, tLogOut, tURLPath, tFilePath, tFile As String
  tRequest = ""
  x = ""
  y = ""
  z = ""
  tLogOut = ""
  tURLPath = "/GospelWorld/"                      ' Place your URL form path to where this page is placed.

  If Len(Request.QueryString("x")) = 0 And Len(Request.QueryString("y")) = 0 And Len(Request.QueryString("z")) = 0 Then
   tRequest = Request.ServerVariables("PATH_INFO").ToString().Replace(tURLPath.ToString() + "map.aspx/", "")
   If Trace.IsEnabled Then Trace.Warn("Map", "Passed by URL: " + tRequest.ToString())
   tLogOut = "Request: " + tRequest.ToString()
   ' Get image name parsed
   InParm = tRequest.ToString().Split("-")
   z = InParm(1)
   x = InParm(2)
   y = InParm(3)
  Else
   If Trace.IsEnabled Then Trace.Warn("Map", "Passed values: " + Request.QueryString().ToString())
   x = Request.QueryString("x")
   y = Request.QueryString("y")
   z = Request.QueryString("z")
  End If
  ' After parsing out the request, locate the actual image in the maptiles folder returning it else send ocean.jpg.
  If Trace.IsEnabled Then Trace.Warn("Map", "Values: x=" + x.ToString() + ", y=" + y.ToString() + ", z=" + z.ToString())
  ' Check if file exists
  tFilePath = Server.MapPath(tURLPath.ToString().Replace("/", "\") + "maptiles\").ToString()
  tFile = x.ToString() + "-" + y.ToString() + "-" + z.ToString() + ".jpg"
  If Trace.IsEnabled Then Trace.Warn("Map", "Seleted file: " + tFilePath.ToString() + tFile.ToString())
  Response.Clear()
  Response.ContentType = "image/jpg"
  If System.IO.File.Exists(tFilePath + tFile) Then
   tLogOut = tLogOut.ToString() + ", sent back " + tFilePath.ToString() + tFile.ToString()
   If Not Trace.IsEnabled Then
    Response.WriteFile(tFilePath + tFile)
   End If
  Else                                                ' Map not found, send ocean.jpg. It must exist and is created by Anaximander.
   tLogOut = tLogOut.ToString() + ", sent back " + tFilePath.ToString() + "maptiles\ocean.jpg"
   If Trace.IsEnabled Then Trace.Warn("Map", "File not found: Sent ocean.jpg")
   If Not Trace.IsEnabled Then
    Response.WriteFile(tFilePath.ToString() + "ocean.jpg")
   End If
  End If

  If False Then                                       ' Set true to turn on process logging
   If Trace.IsEnabled Then Trace.Warn("Map", "Map Logging is active.")
   Dim sw As System.IO.StreamWriter
   tFilePath = Server.MapPath(tURLPath.ToString().Replace("/", "\")).ToString()
   ' Trace Actions to Log file
   sw = System.IO.File.AppendText(tFilePath.ToString() + "MapLog.txt")
   sw.WriteLine(tLogOut)
   sw.Flush()
   sw.Close()
  End If
  Response.End()

 End Sub

 Private Sub Page_Unload(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Unload
  ' Close open page objects
 End Sub
End Class
