package com.github.blueboytm.flutter_v2ray;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import com.github.blueboytm.flutter_v2ray.v2ray.V2rayController;
import com.github.blueboytm.flutter_v2ray.v2ray.V2rayReceiver;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.AppConfigs;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FlutterV2rayPlugin
 */
public class FlutterV2rayPlugin implements FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {

    private static final int REQUEST_CODE_VPN_PERMISSION = 24;
    private static final int REQUEST_CODE_POST_NOTIFICATIONS = 1;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private MethodChannel vpnControlMethod;
    private EventChannel vpnStatusEvent;
    private EventChannel.EventSink vpnStatusSink;
    private Activity activity;
    private BroadcastReceiver v2rayBroadCastReceiver;
    private MethodChannel.Result pendingResult;

    @SuppressLint("DiscouragedApi")
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        vpnControlMethod = new MethodChannel(binding.getBinaryMessenger(), "flutter_v2ray");
        vpnStatusEvent = new EventChannel(binding.getBinaryMessenger(), "flutter_v2ray/status");

        vpnStatusEvent.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                vpnStatusSink = events;
                V2rayReceiver.vpnStatusSink = vpnStatusSink;

                // Register the BroadcastReceiver now that vpnStatusSink is available
                if (v2rayBroadCastReceiver == null) {
                    v2rayBroadCastReceiver = new V2rayReceiver();
                }
                IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
                } else {
                    activity.registerReceiver(v2rayBroadCastReceiver, filter);
                }
            }

            @Override
            public void onCancel(Object arguments) {
                if (vpnStatusSink != null) vpnStatusSink.endOfStream();

                // Unregister the BroadcastReceiver when the stream is canceled
                if (v2rayBroadCastReceiver != null) {
                    activity.unregisterReceiver(v2rayBroadCastReceiver);
                    v2rayBroadCastReceiver = null;
                }
            }
        });

        vpnControlMethod.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "startV2Ray":
                    AppConfigs.NOTIFICATION_DISCONNECT_BUTTON_NAME = call.argument("notificationDisconnectButtonName");
                    if (Boolean.TRUE.equals(call.argument("proxy_only"))) {
                        V2rayController.changeConnectionMode(AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY);
                    }
                    V2rayController.StartV2ray(binding.getApplicationContext(), call.argument("remark"), call.argument("config"), call.argument("blocked_apps"), call.argument("bypass_subnets"));
                    result.success(null);
                    break;
                case "stopV2Ray":
                    V2rayController.StopV2ray(binding.getApplicationContext());
                    result.success(null);
                    break;
                case "initializeV2Ray":
                    String iconResourceName = call.argument("notificationIconResourceName");
                    String iconResourceType = call.argument("notificationIconResourceType");
                    V2rayController.init(binding.getApplicationContext(), binding.getApplicationContext().getResources().getIdentifier(iconResourceName, iconResourceType, binding.getApplicationContext().getPackageName()), "Flutter V2ray");
                    result.success(null);
                    break;
                case "getServerDelay":
                    executor.submit(() -> {
                        try {
                            result.success(V2rayController.getV2rayServerDelay(call.argument("config"), call.argument("url")));
                        } catch (Exception e) {
                            result.success(-1);
                        }
                    });
                    break;
                case "getConnectedServerDelay":
                    executor.submit(() -> {
                        try {
                            AppConfigs.DELAY_URL = call.argument("url");
                            result.success(V2rayController.getConnectedV2rayServerDelay(binding.getApplicationContext()));
                        } catch (Exception e) {
                            result.success(-1);
                        }
                    });
                    break;
                case "getCoreVersion":
                    result.success(V2rayController.getCoreVersion());
                    break;
                case "requestPermission":
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQUEST_CODE_POST_NOTIFICATIONS);
                        }
                    }
                    final Intent request = VpnService.prepare(activity);
                    if (request != null) {
                        pendingResult = result;
                        activity.startActivityForResult(request, REQUEST_CODE_VPN_PERMISSION);
                    } else {
                        result.success(true);
                    }
                    break;
                default:
                    break;
            }
        });
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (v2rayBroadCastReceiver != null) {
            activity.unregisterReceiver(v2rayBroadCastReceiver);
            v2rayBroadCastReceiver = null;
        }
        vpnControlMethod.setMethodCallHandler(null);
        vpnStatusEvent.setStreamHandler(null);
        executor.shutdown();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        // Register the receiver if vpnStatusSink is already set
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink;
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = new V2rayReceiver();
            }
            IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                activity.registerReceiver(v2rayBroadCastReceiver, filter);
            }
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // No additional cleanup required
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);

        // Re-register the receiver if vpnStatusSink is already set
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink;
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = new V2rayReceiver();
            }
            IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                activity.registerReceiver(v2rayBroadCastReceiver, filter);
            }
        }
    }

    @Override
    public void onDetachedFromActivity() {
        // No additional cleanup required
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult.success(true);
            } else {
                pendingResult.success(false);
            }
            pendingResult = null;
        }
        return true;
    }
}
