/*
 Copyright 2012-2013, Polyvi Inc. (http://polyvi.github.io/openxface)
 This program is distributed under the terms of the GNU General Public License.

 This file is part of xFace.

 xFace is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 xFace is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with xFace.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.polyvi.xface.extension.push;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import android.provider.Settings;

/**
 * dependent-libs: asmack.jar
 */
public class XPushNotificationExt extends CordovaPlugin {

	private static final String COMMAND_GETDEVICETOKEN = "getDeviceToken";

	private static final String COMMAND_OPENPUSH = "open";

	private XServiceManager mServiceManager;

	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);
		mServiceManager = new XServiceManager(cordova.getActivity());
		if (mServiceManager.isOpenPush()) {
			mServiceManager.startService();
		}
	}

	@Override
	public boolean execute(String action, JSONArray args,
			CallbackContext callbackContext) throws JSONException {
		if (action.equals(COMMAND_GETDEVICETOKEN)) {
			callbackContext.success(getUuid());
			PluginResult result = new PluginResult(PluginResult.Status.OK);
			callbackContext.sendPluginResult(result);
		} else if (action.equals(COMMAND_OPENPUSH)) {
			if (null != mServiceManager) {
				mServiceManager.stopService();
				mServiceManager.startService(args.getString(0),
						args.getString(1));
			}
			PluginResult result = new PluginResult(
					PluginResult.Status.NO_RESULT);
			result.setKeepCallback(true);
			callbackContext.sendPluginResult(result);
		}
		return true;
	}

	/**
	 * 获得device的Universally Unique Identifier (UUID)
	 */
	private String getUuid() {
		String uuid = Settings.Secure.getString(cordova.getActivity()
				.getContentResolver(),
				android.provider.Settings.Secure.ANDROID_ID);
		return uuid;
	}
}
