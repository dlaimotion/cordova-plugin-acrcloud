/**
 */
package com.dlaimotion;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;
import android.widget.TextView;

import com.acrcloud.rec.sdk.ACRCloudClient;
import com.acrcloud.rec.sdk.ACRCloudConfig;
import com.acrcloud.rec.sdk.IACRCloudListener;

import java.util.Date;

import java.io.File;

import android.app.Activity;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.Menu;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import android.content.Context;

import org.apache.cordova.PermissionHelper;

import android.Manifest;


public class CordovaPluginACRCloud extends CordovaPlugin implements IACRCloudListener {
  private static final String TAG = "CordovaPluginACRCloud";

  private ACRCloudClient mClient;
  private ACRCloudConfig mConfig;

  private String mResult, tv_time;
  private double mVolume;

  private boolean mProcessing = false;
  private boolean initState = false;

  private String path = "";

  private long startTime = 0;
  private long stopTime = 0;

  private CallbackContext resultContext;
  private CallbackContext volumeContext;

  private String [] permissions = { Manifest.permission.RECORD_AUDIO,
                                    Manifest.permission.ACCESS_NETWORK_STATE,
                                    Manifest.permission.ACCESS_WIFI_STATE,
                                    Manifest.permission.INTERNET,
                                    };

  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);

    if(!hasPermisssion()) {
        PermissionHelper.requestPermissions(this, 0, permissions);
    }

  }

  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
     if (action.equals("init")) {

        this.mConfig = new ACRCloudConfig();
        this.mConfig.acrcloudListener = this;

        // If you implement IACRCloudResultWithAudioListener and override "onResult(ACRCloudResult result)", you can get the Audio data.
        //this.mConfig.acrcloudResultWithAudioListener = this;

        this.mConfig.context = cordova.getActivity().getApplicationContext(); /*myContext;*/
        this.mConfig.host = args.getString(2);
        this.mConfig.dbPath = path; // offline db path, you can change it with other path which this app can access.
        this.mConfig.accessKey = args.getString(0);
        this.mConfig.accessSecret = args.getString(1);
        this.mConfig.protocol = ACRCloudConfig.ACRCloudNetworkProtocol.PROTOCOL_HTTPS; // PROTOCOL_HTTPS
        this.mConfig.reqMode = ACRCloudConfig.ACRCloudRecMode.REC_MODE_REMOTE;
        //this.mConfig.reqMode = ACRCloudConfig.ACRCloudRecMode.REC_MODE_LOCAL;
        //this.mConfig.reqMode = ACRCloudConfig.ACRCloudRecMode.REC_MODE_BOTH;

        this.mClient = new ACRCloudClient();
        // If reqMode is REC_MODE_LOCAL or REC_MODE_BOTH,
        // the function initWithConfig is used to load offline db, and it may cost long time.
        this.initState = this.mClient.initWithConfig(this.mConfig);
        if (this.initState) {
          this.mClient.startPreRecord(3000); //start prerecord, you can call "this.mClient.stopPreRecord()" to stop prerecord.
        }

        final PluginResult result = new PluginResult(PluginResult.Status.OK, "success");
        callbackContext.sendPluginResult(result);

    } else if(action.equals("startRecognition")) {

        if (!this.initState) {
            return false;
        }

        if (!mProcessing) {
            mProcessing = true;
            mVolume = 0.0;
            mResult = "";
            if (this.mClient == null || !this.mClient.startRecognize()) {
                mProcessing = false;
                mResult = "start error!";
            }
            startTime = System.currentTimeMillis();
        }

        resultContext = callbackContext;

    } else if(action.equals("stopRecognition")) {

        if (mProcessing && this.mClient != null) {
            this.mClient.stopRecordToRecognize();
        }
        mProcessing = false;

        stopTime = System.currentTimeMillis();

    } else if(action.equals("watchForVolumeChange")) {

        volumeContext = callbackContext;

    }
    return true;
  }






  /////

    @Override
    public void onResult(String result) {
        if (this.mClient != null) {
            this.mClient.cancel();
            mProcessing = false;
        }

        String tres = "\n";

        try {
            JSONObject j = new JSONObject(result);
            JSONObject j1 = j.getJSONObject("status");
            int j2 = j1.getInt("code");
            if(j2 == 0){
                JSONObject metadata = j.getJSONObject("metadata");
                //
                if (metadata.has("humming")) {
                    JSONArray hummings = metadata.getJSONArray("humming");
                    for(int i=0; i<hummings.length(); i++) {
                        JSONObject tt = (JSONObject) hummings.get(i);
                        String title = tt.getString("title");
                        JSONArray artistt = tt.getJSONArray("artists");
                        JSONObject art = (JSONObject) artistt.get(0);
                        String artist = art.getString("name");
                        tres = tres + (i+1) + ".  " + title + "\n";
                    }
                }
                if (metadata.has("music")) {
                    JSONArray musics = metadata.getJSONArray("music");
                    for(int i=0; i<musics.length(); i++) {
                        JSONObject tt = (JSONObject) musics.get(i);
                        String title = tt.getString("title");
                        JSONArray artistt = tt.getJSONArray("artists");
                        JSONObject art = (JSONObject) artistt.get(0);
                        String artist = art.getString("name");
                        tres = tres + (i+1) + ".  Title: " + title + "    Artist: " + artist + "\n";
                    }
                }
                if (metadata.has("streams")) {
                    JSONArray musics = metadata.getJSONArray("streams");
                    for(int i=0; i<musics.length(); i++) {
                        JSONObject tt = (JSONObject) musics.get(i);
                        String title = tt.getString("title");
                        String channelId = tt.getString("channel_id");
                        tres = tres + (i+1) + ".  Title: " + title + "    Channel Id: " + channelId + "\n";
                    }
                }
                if (metadata.has("custom_files")) {
                    JSONArray musics = metadata.getJSONArray("custom_files");
                    for(int i=0; i<musics.length(); i++) {
                        JSONObject tt = (JSONObject) musics.get(i);
                        String title = tt.getString("title");
                        tres = tres + (i+1) + ".  Title: " + title + "\n";
                    }
                }
                tres = tres + "\n\n" + result;
            }else{
                tres = result;
            }
        } catch (JSONException e) {
            tres = result;
            e.printStackTrace();
        }

        mResult = result;
        sendPluginResult("recognition_response");
    }



  @Override
  public void onVolumeChanged(double volume) {
      long time = (System.currentTimeMillis() - startTime) / 1000;
      mVolume = volume;
      sendPluginResult("volume");
  }

  public void sendPluginResult(String resultType) {

      PluginResult pluginResult = null;
      CallbackContext ctx = null;

      if (resultType.equals("recognition_response")) {
          pluginResult = new PluginResult(PluginResult.Status.OK, mResult);
          ctx = resultContext;
      } else if (resultType.equals("volume")) {
          pluginResult = new PluginResult(PluginResult.Status.OK, (float)mVolume);
          ctx = volumeContext;
      }

      pluginResult.setKeepCallback(true);
      ctx.sendPluginResult(pluginResult);
  }

    public boolean hasPermisssion() {
        for(String p : permissions)
        {
            if(!PermissionHelper.hasPermission(this, p))
            {
                return false;
            }
        }
        return true;
    }

}
