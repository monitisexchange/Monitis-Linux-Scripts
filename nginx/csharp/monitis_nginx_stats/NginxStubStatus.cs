using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.IO;

namespace monitis_nginx_stats
{
    class NginxStubStatus
    {
        private String STATUS_PAGE;
        //http://wiki.nginx.org/HttpStubStatusModule
        private int ACTIVE_CONNECT; //number of all open connections including connections to backends
        private int ACCEPT; //accepted connections
        private int HANDLED_CONNECT; //handled connections
        private int HANDLED_REQ; //handles requests
        private int READ; //nginx reads request header 
        private int WRITE; //nginx reads request body, processes request, or writes response to a client
        private int WAIT; //keep-alive connections, actually it is active - (reading + writing)

        public NginxStubStatus(String status_page)
        {
            STATUS_PAGE = status_page;
        }
    
        //fetch the raw page
        //example http://localhost/nginx_status
        private String fetch_nginx_status_page()
        {
            WebRequest request;
            request = WebRequest.Create(STATUS_PAGE);
            Stream objStream;
            objStream = request.GetResponse().GetResponseStream();
            StreamReader objReader = new StreamReader(objStream);
            String result = objReader.ReadToEnd();
            
            return result;
        }

        public String getNginxStatsResultForMonitis()
        {
            String page = fetch_nginx_status_page();
            parse_nginx_status_page(page);

            //paramName1:paramValue1[;paramName2:paramValue2...] 
            //http://monitis.com/api/api.html#addCustomMonitorResults
            return   "ActiveConnect:" + ACTIVE_CONNECT
                   + ";Accept:" + ACCEPT
                   + ";Handled:" + HANDLED_CONNECT
                   + ";Handles:" + HANDLED_REQ
                   + ";Read:" + READ
                   + ";Write:" + WRITE
                   + ";Wait:" + WAIT;   
        }

        //parse the raw page (nginx1.11 in windows)
        //example of stats: 
        //Active connections: 1
        //server accepts handled requests
        //1 1 1 
        //Reading: 0 Writing: 1 Waiting: 0
        private void parse_nginx_status_page(String page)
        {
            String[] lines = page.Split('\n');
            parse_active_connection(lines[0]);
            //line[1] = server accepts handled requests
            parse_request(lines[2]);
            parse_read_write_wait(lines[3]);           
        }

        //Active connections: 1
        //TODO: int32 large enough to hold the value?
        private void parse_active_connection(String line)
        {
            String data = line.Substring(line.IndexOf(":")+2);
            data = data.Replace(" ", String.Empty);
            ACTIVE_CONNECT = Convert.ToInt32(data);          
        }

        //server accepts handled requests
        //1 1 1 
        //TODO: INT32 large enough to hold the value?
        private void parse_request(String line)
        {
            String[] requests = line.Split(' ');            
            ACCEPT = Convert.ToInt32(requests[1]);
            HANDLED_CONNECT = Convert.ToInt32(requests[2]);
            HANDLED_REQ = Convert.ToInt32(requests[3]);
            //requests[0] and requests[4] are spaces
        }

        //Reading: 0 Writing: 1 Waiting: 0
        //TODO: INT32 large enough to hold the value?
        private void parse_read_write_wait(String line)
        {
            String data = line.ToUpper();
            data = data.Replace("READING", String.Empty);
            data = data.Replace("WRITING", String.Empty);
            data = data.Replace("WAITING", String.Empty);
            data = data.Replace(":", String.Empty);
            String[] stats = data.Split(' ');
            READ = Convert.ToInt32(stats[1]);
            WRITE = Convert.ToInt32(stats[3]);
            WAIT = Convert.ToInt32(stats[5]);
            //stats[0], stats[2], stats[4] and stats[6] are spaces;
        }
    }
}