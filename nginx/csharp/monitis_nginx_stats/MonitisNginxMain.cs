using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace monitis_nginx_stats
{
    class MonitisNginxMain
    {
        static void Main(string[] args)
        {
            //The server needs to have Nginx Started and enable the StubStatus Module
            //Monitor name has to be unique; tag has to be unique
            String apiKey = "14NAC40PIMSUEEBQFJOQL18T5U";
            String apiSecret = "74H6U7A2DG71JU80QR48FEOPAL";
            String customMonitorName = "Nginx Stub Status";
            String customMonitorTag = "Nginx+StubStatus";
            String nginxStatusPageURL = "http://localhost/nginx_status";
            int sleepTime = 30000;
            
            //Create our customer monitior for Monitis
            MonitisServer ms = new MonitisServer(apiKey, apiSecret, customMonitorName,customMonitorTag);
            ms.addCustomMonitor();
 
            //Ready to send Nginx Stats to the custom monitor
            NginxStubStatus ar = new NginxStubStatus(nginxStatusPageURL);
            String monitorTag = ms.getMonitorTag();
            String result; 
            int count = 0;            

            for(;;)
            {
                count += 1;
                try
                {
                    result = ar.getNginxStatsResultForMonitis(); 
                    ms.addResult("", monitorTag , result);
                    Console.WriteLine(count + " Sending Stats...");
                    Console.WriteLine(result);
                    Thread.Sleep(sleepTime);
                }
                catch (Exception e)
                {
                    Console.WriteLine("An error occurred.\n\n");
                    Console.WriteLine(e.ToString());
                    Console.ReadLine();
                    Environment.Exit(0);
                }              
            }
        }
    }
}
