using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Net.Cache;

namespace monitis_nginx_stats
{
    //Create a custom monitor with Monitis API
    //http://monitis.com/api/api.html#addCustomMonitor
    //Author Glenn Y. Chen
    //todo: support reading configuration file
    //todo: support reading configuration from command line
    class MonitisServer
    {
        //required fields
        private String API_URL;
        private String API_KEY; 
        private String SECRET_KEY ;
        private String ACTION;
        private String TIMESTAMP;  //datetime
        private String VALIDATION; 
        private String AUTH_TOKEN; 
        private String CHECKSUM; 
        private String VERSION;  //integer
        private String RESULT_PARAMS; 
        private String NAME;
        private String TAG; 

        //optional fields
        private String MONITOR_PARAMS = "";
        private String ADDITIONAL_RESULT_PARAMS = "";
        private String CUSTOM_USER_AGENT_ID = "";
        private String TYPE = "";

        public MonitisServer(String apiKey, String apiSecret,
                             String name, String tag)
        {
            //required fields
            API_URL = "http://monitis.com/customMonitorApi";
            API_KEY = apiKey; // "1R554GTHTDVSCAKOLVU1OVPP52";
            SECRET_KEY = apiSecret; // "756JCGTTD3M1D40TRAA9GOSR1M";
            ACTION = "addMonitor";
            TIMESTAMP = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"); //datetime
            VALIDATION = "token"; //TODO:support checksum validation
            AUTH_TOKEN = get_user_auth_token();
            CHECKSUM = "";
            VERSION = "2"; //integer
            RESULT_PARAMS = "";
            NAME = name;
            TAG = tag;

            //optional fields
            MONITOR_PARAMS = "";
            ADDITIONAL_RESULT_PARAMS = "";
            CUSTOM_USER_AGENT_ID = "";
            TYPE = "";
        }

        //Monitor name has to be unique; tag has to be unique
        public void addCustomMonitor()
        {
            String POST_DATA = this.buildAddCustomMonitorPostData();

            if (foundDuplicateMonitor())
            {
                monitisHttpPost(API_URL, POST_DATA);
            }
            else{
                // TODO: notify the user 
                // that she is trying to add a monitor with the same tag                
            }
        }

        public String addResult(String monitor_id, String monitor_tag, String result)
        {
            List<String> post_data = new List<String>();
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            TimeSpan span = DateTime.UtcNow - new DateTime(1970, 1, 1);
            long millis = (long)span.TotalMilliseconds;
            string checktime = millis.ToString();

            if (monitor_id == "")
            {
                monitor_id = get_monitor_id(monitor_tag);
            }
            
            post_data.Add("apikey=" + API_KEY);
            post_data.Add("validation=" + VALIDATION);
            post_data.Add("authToken=" + AUTH_TOKEN);
            post_data.Add("version=" + VERSION);
            post_data.Add("action=addResult");
            post_data.Add("monitorId=" + monitor_id);
            post_data.Add("timestamp=" + timestamp);
            post_data.Add("checktime=" + checktime);                       
            post_data.Add("results=" + result);

            StringBuilder post_args = new StringBuilder();
            foreach (String arg in post_data)
            {
                post_args.Append(arg);
                post_args.Append("&");
            }

            return monitisHttpPost(API_URL, post_args.ToString());
        }

        //todo: support validation=token or checksum
        public String buildAddCustomMonitorPostData()
        {
            StringBuilder POST_DATA = new StringBuilder();
            POST_DATA.Append("apikey=" + API_KEY + "&");
            POST_DATA.Append("validation=" + VALIDATION + "&");
            POST_DATA.Append("authToken=" + AUTH_TOKEN + "&");
            POST_DATA.Append("timestamp=" + TIMESTAMP + "&");
            POST_DATA.Append("version=" + VERSION + "&");
            POST_DATA.Append("action=" + ACTION + "&");

            String activeConnections = "ActiveConnect:ActiveConnect:ActiveConnects:2;";
            String accept = "Accept:Accept:Accepts:2;";
            String handled = "Handled:Handled:Handleds:2;";
            String handles = "Handles:Handles:Handle:2;";
            String read = "Read:Read:Reads:2;";
            String write = "Write:Write:Writes:2;";
            String wait = "Wait:Wait:Waits:2;";
            String resultParams = "resultParams=" + wait + write + read + handles + handled + accept + activeConnections;
            POST_DATA.Append(resultParams+"&");

            POST_DATA.Append("name="+ NAME + "&");
            POST_DATA.Append("tag=" + TAG+ "&");

            return POST_DATA.ToString();
        }

        public String monitisHttpPost(String api_url, String post_data)
        {
            WebRequest request;
            request = WebRequest.Create(api_url);
            request.Method = "POST";

            byte[] byteArray = Encoding.UTF8.GetBytes(post_data);
            request.ContentType = "application/x-www-form-urlencoded";
            request.ContentLength = byteArray.Length;

            Stream objStream;
            objStream = request.GetRequestStream();
            objStream.Write(byteArray, 0, byteArray.Length); 
            
            Stream response_stream = request.GetResponse().GetResponseStream();

            StreamReader objReader = new StreamReader(response_stream);
            String response = objReader.ReadToEnd();
           
            objStream.Close();
            response_stream.Close();

            return response;
        }

        public String monitisHttpGet(String url_and_parameter)
        {
            WebRequest request;
            request = WebRequest.Create(url_and_parameter);
            HttpRequestCachePolicy noCachePolicy = new HttpRequestCachePolicy(HttpRequestCacheLevel.NoCacheNoStore);
            request.CachePolicy = noCachePolicy;
 
            Stream objStream;
            objStream = request.GetResponse().GetResponseStream();

            StreamReader objReader = new StreamReader(objStream);
            String response = objReader.ReadToEnd();

            objStream.Close();
            objReader.Close();

            return response;
        }

        private void getCheckSum()
        {            

        }
        
        //get request to fetch our authentication toekn, version=2
        public String build_user_auth_token_request()
        {
            StringBuilder GET_DATA = new StringBuilder();
            GET_DATA.Append("http://www.monitis.com/api?");
            GET_DATA.Append("action=authToken&");
            GET_DATA.Append("apikey=" + API_KEY + "&");
            GET_DATA.Append("secretkey=" + SECRET_KEY + "&");
            GET_DATA.Append("version=" + VERSION);
            return GET_DATA.ToString();
        }

        //http get request to fetch auth token 
        public String get_user_auth_token()
        {
            String request_url = this.build_user_auth_token_request();
            String response = monitisHttpGet(request_url);

            // parse response, example: {"authToken":"1OI298DTD19IT97QG7GBOQMFNO"}
            int start_index = response.IndexOf(":\"") + 2; //skip :"
            int end_index = response.IndexOf("\"}"); //grab before "}
            int length = end_index - start_index;
            return response.Substring(start_index, length);
        }

        public String get_monitor_id(String monitor_tag)
        {
            String url = "http://www.monitis.com/customMonitorApi";
            String apikey = "apikey=" + API_KEY;
            String xml_output = "output=xml";
            String version = "version=" +VERSION;
            String action = "action=getMonitors";
            String tag = "tag=" + monitor_tag;

            String request_url = url + "?" + apikey + "&" + xml_output + "&" + version + "&" + action + "&" + tag;

            String response = monitisHttpGet(request_url);
            XElement response_xml = XElement.Parse(response);

            //exception will throw if trying to get the id of a monitor which just got deleted
            String id = (String)
                        (from el in response_xml.Descendants("id")
                         select el).First();
           
            return id;
        }

        public XElement listMonitors()
        {
            String url = "http://www.monitis.com/customMonitorApi";
            String apikey = "apikey=" + API_KEY;
            String xml_output = "output=xml";
            String version = "version=" + VERSION;
            String action = "action=getMonitors";
            String tag = "tag=" + TAG;

            String request_url = url + "?" + apikey + "&" + xml_output + "&" + version + "&" + action + "&" + tag;

            String response = monitisHttpGet(request_url);
            XElement response_xml = XElement.Parse(response);

            return response_xml;
        }

         private bool foundDuplicateMonitor()
        {
            XElement monitorList = listMonitors();

            //var id = (from el in monitorList.Descendants("tag")
            //         select el);

            String theTag = TAG.Replace("+", " ");
            var monitors = (from el in monitorList.Elements("monitor")
                            where (String) el.Element("tag") == theTag &&
                                  (String) el.Element("name") == NAME &&
                                  (String) el.Element("type") == "custom"
                            select el);


            if (monitors.Count() == 0)
            {
                //Not found duplicate custom monitor with the same name and same tag
                return true;
            }

            //found duplicate custom monitor with the same name and same tag
            return false;

        }

        public String getMonitorTag()
        {
            return TAG;
        }
    }
}
