using System.Windows;
using System.IO.IsolatedStorage;
using xFaceLib.runtime;
using xFaceLib.Util;
using xFaceLib.Log;

namespace WPCordovaClassLib.Cordova.Commands
{
    public class PushNotification : XBaseCommand
    {

        /// <summary>
        /// 获取手机设备的唯一标识(以UUID作为唯一标识)
        /// </summary>
        public void getDeviceToken(string options)
        {
            string pushChannelUri = string.Empty;
            if (IsolatedStorageSettings.ApplicationSettings.Contains(XConstant.PUSH_NOTIFICATION_URI))
            {
                pushChannelUri = (string)IsolatedStorageSettings.ApplicationSettings[XConstant.PUSH_NOTIFICATION_URI];
                DispatchCommandResult(new PluginResult(PluginResult.Status.OK, pushChannelUri));
            }
            else
            {
                DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR, "can't get pushChannelUri"));
            }
        }

        /// <summary>
        /// 注册一个监听器，当手机收到推送消息时，该监听器会被回调
        /// </summary>
        public void registerOnReceivedListener(string options)
        {
            XPushNotificationHelper.PushNotificationEventHandler += XPushNotificationHelper_PushNotificationEventHandler;
        }

        private void XPushNotificationHelper_PushNotificationEventHandler(object sender, string notification)
        {
            Fire(notification);
        }

        private void Fire(string notification)
        {
            Deployment.Current.Dispatcher.BeginInvoke(() =>
            {
                //替掉行符"\n"为"\\n",否则会引起js语句异常
                notification = notification.Replace("\n", "\\n");
                string jsString = string.Format("cordova.require('com.polyvi.xface.extension.push.PushNotification').fire('{0}');", notification);
                // Fire notification to js

                var Invoker = new XSafeBrowserScriptInvoker();
                if (!Invoker.Exec(this.app.AppView.Browser, "eval", new string[] { jsString }))
                {
                    XLog.WriteError("Failed Fire Push notification!");
                }
            });
        }

        //处理OnReset 移除push监听
        public override void OnReset()
        {
            XPushNotificationHelper.PushNotificationEventHandler -= XPushNotificationHelper_PushNotificationEventHandler;
        }
    }
}
