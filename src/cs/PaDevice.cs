using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Web;
using System.Xml;
using System.Xml.Linq;
using System.Text.RegularExpressions;

namespace PowerAlto {
/*
	public class HelperClass {
		public string paAlphaNum (string Name) {
			string namePattern =  @"^[a-zA-Z0-9\-_\.]+$";
			Regex nameRx = new Regex(namePattern);
			Match nameMatch = nameRx.Match(Name);
			if (nameMatch.Success) {
				return Name;
			} else {
				throw new System.ArgumentException("Value can only contain alphanumeric, hyphens, underscores, or periods.");
			}
		}
	}
*/
	public class PaDevice {
		// can we rewrite the helper functions as methods in this class?
		
		private DateTime clock;
		private Stack<string> urlhistory = new Stack<string>();
		private string poweraltoversion = "2.0";
		
		public string Device { get; set; }
		public int Port { get; set; }
		public string ApiKey { get; set; }
		public string Protocol { get; set; }
		
		public string Name { get; set; }
		public string Model { get; set; }
		public string Serial { get; set; }
		
		public string OsVersion { get; set; }
		public string GpAgent { get; set; }
		public string AppVersion { get; set; }
		public string ThreatVersion { get; set; }
		public string WildFireVersion { get; set; }
		public string UrlVersion { get; set; }
		public XmlDocument LastXmlResult { get; set; }
		
		public string ApiUrl {
			get {
				if (!string.IsNullOrEmpty(this.Protocol) && !string.IsNullOrEmpty(this.Device) && this.Port > 0) {
					return this.Protocol + "://" + this.Device + ":" + this.Port + "/api/";
				} else {
					return null;
				}
			}
		}
		
		public string AuthString {
			get {
				if (!string.IsNullOrEmpty(this.ApiKey)) {
					return "key=" + this.ApiKey;
				} else {
					return null;
				}
			}
		}

	
		public string PowerAltoVersion {
			get {
				return this.poweraltoversion;
			}
		}
	
		public string Clock {
			get {
				return this.clock.ToString();
			}
			set {
				this.clock = DateTime.Parse(value);
			}
		}
		public DateTime ClockasDateTime {
			get {
				return this.clock;
			}
			set {
				this.clock = value;
			}
		}
		
		public string[] UrlHistory {
			get {
				return this.urlhistory.ToArray();
			}
		}
		
		public void FlushHistory () {
			this.urlhistory.Clear();
		}
		
		
		public string UrlBuilder (string QueryString) {
			
			string[] Pieces = new string[5];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = "?";
			Pieces[2] = this.AuthString;
			Pieces[3] = "&";
			Pieces[4] = QueryString;
			
			//if (QueryType == "op") {
			//	Pieces[5] += ("&cmd=" + Query);
			//}
			
			string CompletedString = string.Join ("",Pieces);
			
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
				
		private static bool OnValidateCertificate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) {
			return true;
		}
    
		public void OverrideValidation() {
			ServicePointManager.ServerCertificateValidationCallback = OnValidateCertificate;
			ServicePointManager.Expect100Continue = true;
			ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3;
		}
		
		//Holds the raw result of the last query
		//Would like to convert this to emulate UrlHistory, but I think we need to get the HttpQuery helper as a method to PaDevice first
		
	}
}