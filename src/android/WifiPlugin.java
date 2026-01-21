package wifiplugin;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.DhcpInfo;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.NetworkInfo;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.text.format.Formatter;
import androidx.annotation.RequiresApi;
import android.net.wifi.WifiNetworkSpecifier;
import android.net.NetworkSpecifier;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

import java.util.List;

public class WifiPlugin extends CordovaPlugin {
    private static final String TAG = "WifiPlugin";
    private static final int MY_PERMISSIONS_REQUEST_WIFI_STATE = 1;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("getWifiList".equals(action)) {
            WifiUtils.getWifiList(cordova, callbackContext);
            return true;
        } else if ("ping".equals(action)) {
            String address = args.getString(0);
            int count = args.getInt(1);
            int timeout = args.getInt(2);
//             PingTask.ping(address, count, timeout, callbackContext, cordova);
            return true;
        } else if ("getIpInfo".equals(action)) {
            IpInfoUtils.getIpInfo(cordova, callbackContext);
            return true;
        } else if ("getSignalStrength".equals(action)) {
            getSignalStrength(callbackContext);
            return true;
        } else if ("getWifiStrength".equals(action)) {
            getWifiStrength(callbackContext);
            return true;
        } else if ("getAllWifiDetails".equals(action)) {
            WifiDetailsUtils.getAllWifiDetails(cordova, callbackContext);
            return true;
        } else if ("getConnectedDevices".equals(action)) {
            WifiUtils.getConnectedDevices(cordova.getActivity().getApplicationContext(), cordova, callbackContext);
            return true;
        } else if ("isConnectedToInternet".equals(action)) {
            isConnectedToInternet(callbackContext);
            return true;
        } else if ("canConnectToInternet".equals(action)) {
            canConnectToInternet(callbackContext);
            return true;
        } else if ("canConnectToRouter".equals(action)) {
            canConnectToRouter(callbackContext);
            return true;
        } else if ("connectToNetwork".equals(action)) {
            String ssid = args.optString(0);
            String password = args.optString(1);
            connectToWifi(ssid, password, callbackContext);
            return true;
        } else if ("disconnectFromNetwork".equals(action)) {
            disconnectFromNetwork(callbackContext);
            return true;
        } else if ("isWifiEnabled".equals(action)) {
            isWifiEnabled(callbackContext);
            return true;
        } else if ("wifiToggle".equals(action)) {
            wifiToggle(callbackContext);
            return true;
        } else if ("getNetworkDiagnostics".equals(action)) {
            getNetworkDiagnostics(callbackContext);
            return true;
        }
        return false;
    }

    private void getSignalStrength(CallbackContext callbackContext) {
        WifiUtils.getSignalStrength(cordova.getActivity().getApplicationContext(), callbackContext);
    }

    private void getWifiStrength(CallbackContext callbackContext) {
        WifiUtils.getWifiStrength(cordova.getActivity().getApplicationContext(), callbackContext);
    }

    private void wifiToggle(CallbackContext callbackContext) {
        cordova.getThreadPool().execute(() -> {
            try {
                WifiManager wifiManager = (WifiManager) cordova.getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                if (wifiManager != null) {
                    wifiManager.setWifiEnabled(!wifiManager.isWifiEnabled());
                    callbackContext.success();
                } else {
                    callbackContext.error("Error toggling Wi-Fi");
                }
            } catch (Exception e) {
                callbackContext.error("Error toggling Wi-Fi: " + e.getMessage());
            }
        });
    }

    private void isWifiEnabled(CallbackContext callbackContext) {
        try {
            WifiManager wifiManager = (WifiManager) cordova.getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            boolean isEnabled = wifiManager.isWifiEnabled();
            callbackContext.success(isEnabled ? 1 : 0);
        } catch (Exception e) {
            callbackContext.error("Error checking Wi-Fi status: " + e.getMessage());
        }
    }

    private void isConnectedToInternet(CallbackContext callbackContext) {
       ConnectivityManager connectivityManager = (ConnectivityManager) cordova.getActivity().getSystemService(Context.CONNECTIVITY_SERVICE);
       if (connectivityManager != null) {
           if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
              Network network = connectivityManager.getActiveNetwork();
                     if (network != null) {
                         NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(network);
                         if (networkCapabilities != null) {
                             boolean isConnected = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                                                   networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);

                             if (isConnected) {
                                 boolean isWiFi = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
                                 boolean isCellular = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR);
                                 boolean isVPN = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN);

                                 // You can now use these flags to determine the type of connection
                                 if (isWiFi) {
                                     // Connected via WiFi
                Log.d(TAG, "Connected via WiFi");
                                     callbackContext.success(1); // or handle accordingly
                                 } else if (isCellular) {
                                     // Connected via Cellular
                Log.d(TAG, "Connected via Cellular");
                                     callbackContext.success(1); // or handle accordingly
                                 } else if (isVPN) {
                                     // Connected via VPN
                Log.d(TAG, "Connected via VPN");
                                     callbackContext.success(1); // or handle accordingly
                                 } else {
                                     // Unknown or unsupported transport
                Log.d(TAG, "Connected via Unknown or unsupported transport");
                                     callbackContext.success(1); // or handle accordingly
                                 }
                             } else {
                                 callbackContext.success(0); // No internet connection
                             }
                         } else {
                             callbackContext.success(0); // No internet connection
                         }
                     } else {
                         callbackContext.success(0); // No network connection
                     }
           } else {
               // For devices with SDK < 23, you can still use the deprecated method
               NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
               boolean isConnected = activeNetworkInfo != null && activeNetworkInfo.isConnected();
               callbackContext.success(isConnected ? 1 : 0);
           }
       } else {
                Log.e(TAG, "ConnectivityManager is null");
                callbackContext.success(0);
       }
    }

    private void canConnectToInternet(CallbackContext callbackContext) {
        ConnectivityManager connectivityManager = (ConnectivityManager) cordova.getActivity().getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivityManager != null) {
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(connectivityManager.getActiveNetwork());
            boolean canConnect = capabilities != null && capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
            callbackContext.success(canConnect ? 1 : 0);
        } else {
            callbackContext.error("ConnectivityManager is null");
        }
    }

    private void canConnectToRouter(CallbackContext callbackContext) {
        ConnectivityManager connectivityManager = (ConnectivityManager) cordova.getActivity().getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivityManager != null) {
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(connectivityManager.getActiveNetwork());
            boolean canConnectToRouter = capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
            callbackContext.success(canConnectToRouter ? 1 : 0);
        } else {
            callbackContext.error("ConnectivityManager is null");
        }
    }

    public void connectToWifi(String ssid, String password, CallbackContext callbackContext) {
        WifiManager wifiManager = (WifiManager) cordova.getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE);

        if (!wifiManager.isWifiEnabled()) {
            wifiManager.setWifiEnabled(true);
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            connectToWifiPreQ(wifiManager, ssid, password, callbackContext);
        } else {
            connectToWifiQAndAbove(ssid, password, callbackContext);
        }
    }

    private void connectToWifiPreQ(WifiManager wifiManager, String ssid, String password, CallbackContext callbackContext) {
        WifiConfiguration wifiConfig = new WifiConfiguration();
        wifiConfig.SSID = "\"" + ssid + "\"";
        wifiConfig.preSharedKey = "\"" + password + "\"";
        wifiConfig.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);

        // Remove existing configurations for the same SSID
        List<WifiConfiguration> configuredNetworks = wifiManager.getConfiguredNetworks();
        if (configuredNetworks != null) {
            for (WifiConfiguration existingConfig : configuredNetworks) {
                if (existingConfig.SSID != null && existingConfig.SSID.equals(wifiConfig.SSID)) {
                    wifiManager.removeNetwork(existingConfig.networkId);
                }
            }
        }

        int networkId = wifiManager.addNetwork(wifiConfig);
        if (networkId != -1) {
            wifiManager.disconnect();
            wifiManager.enableNetwork(networkId, true);
            wifiManager.reconnect();

            callbackContext.success("Connected to Wi-Fi network: " + ssid);
        } else {
            callbackContext.error("Failed to add Wi-Fi network configuration");
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private void connectToWifiQAndAbove(String ssid, String password, CallbackContext callbackContext) {
        WifiNetworkSpecifier.Builder builder = new WifiNetworkSpecifier.Builder()
           .setSsid(ssid)
           .setWpa2Passphrase(password);
WifiManager wifiManager = (WifiManager) cordova.getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE);
       NetworkSpecifier specifier = builder.build();

       NetworkRequest request = new NetworkRequest.Builder()
           .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
           .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
           .setNetworkSpecifier(specifier)
           .build();

       ConnectivityManager connectivityManager = (ConnectivityManager) cordova.getActivity().getSystemService(Context.CONNECTIVITY_SERVICE);
       connectivityManager.requestNetwork(request, new ConnectivityManager.NetworkCallback() {
           @Override
           public void onAvailable(Network network) {
               super.onAvailable(network);
               wifiManager.setWifiEnabled(false);

               callbackContext.success("Connected to Wi-Fi network: " + ssid);
           }

           @Override
           public void onUnavailable() {
               super.onUnavailable();
               callbackContext.error("Failed to connect to Wi-Fi network");
           }
       });
    }

    private void disconnectFromNetwork(CallbackContext callbackContext) {
        WifiManager wifiManager = (WifiManager) cordova.getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE);

        if (!wifiManager.isWifiEnabled()) {
            callbackContext.error("Wi-Fi is disabled");
            return;
        }

        wifiManager.disconnect();
        callbackContext.success("Disconnected from Wi-Fi network");
    }

    private void getNetworkDiagnostics(CallbackContext callbackContext) {
        cordova.getThreadPool().execute(() -> {
            try {
                JSONObject diagnostics = new JSONObject();
                Context context = cordova.getActivity().getApplicationContext();

                // Get connectivity information
                ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
                WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

                // Connection status
                JSONObject connectionStatus = new JSONObject();
                boolean isConnectedToInternet = false;
                boolean isConnectedToWifi = false;
                String connectionType = "None";

                if (connectivityManager != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Network network = connectivityManager.getActiveNetwork();
                        if (network != null) {
                            NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(network);
                            if (networkCapabilities != null) {
                                isConnectedToInternet = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                                                       networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);
                                isConnectedToWifi = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);

                                if (isConnectedToWifi) {
                                    connectionType = "WiFi";
                                } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                                    connectionType = "Cellular";
                                } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                                    connectionType = "VPN";
                                } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                                    connectionType = "Ethernet";
                                }
                            }
                        }
                    } else {
                        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
                        isConnectedToInternet = activeNetworkInfo != null && activeNetworkInfo.isConnected();
                        if (activeNetworkInfo != null) {
                            connectionType = activeNetworkInfo.getTypeName();
                            isConnectedToWifi = activeNetworkInfo.getType() == ConnectivityManager.TYPE_WIFI;
                        }
                    }
                }

                connectionStatus.put("isConnectedToInternet", isConnectedToInternet);
                connectionStatus.put("isConnectedToWifi", isConnectedToWifi);
                connectionStatus.put("connectionType", connectionType);
                connectionStatus.put("isWifiEnabled", wifiManager != null && wifiManager.isWifiEnabled());
                diagnostics.put("connectionStatus", connectionStatus);

                // WiFi details (if connected)
                if (isConnectedToWifi && wifiManager != null) {
                    WifiInfo wifiInfo = wifiManager.getConnectionInfo();
                    DhcpInfo dhcpInfo = wifiManager.getDhcpInfo();

                    JSONObject wifiDetails = new JSONObject();
                    wifiDetails.put("ssid", wifiInfo.getSSID().replace("\"", ""));
                    wifiDetails.put("bssid", wifiInfo.getBSSID());
                    wifiDetails.put("ipAddress", Formatter.formatIpAddress(wifiInfo.getIpAddress()));
                    wifiDetails.put("macAddress", wifiInfo.getMacAddress());
                    wifiDetails.put("linkSpeed", wifiInfo.getLinkSpeed());
                    wifiDetails.put("linkSpeedUnit", "Mbps");
                    wifiDetails.put("rssi", wifiInfo.getRssi());
                    wifiDetails.put("frequency", wifiInfo.getFrequency());
                    wifiDetails.put("channel", getChannelFromFrequency(wifiInfo.getFrequency()));
                    wifiDetails.put("gateway", Formatter.formatIpAddress(dhcpInfo.gateway));
                    wifiDetails.put("dns1", Formatter.formatIpAddress(dhcpInfo.dns1));
                    wifiDetails.put("dns2", Formatter.formatIpAddress(dhcpInfo.dns2));
                    wifiDetails.put("networkId", wifiInfo.getNetworkId());

                    // Signal quality
                    int signalLevel = WifiManager.calculateSignalLevel(wifiInfo.getRssi(), 5);
                    String signalQuality;
                    if (signalLevel >= 4) signalQuality = "excellent";
                    else if (signalLevel >= 3) signalQuality = "good";
                    else if (signalLevel >= 2) signalQuality = "fair";
                    else signalQuality = "poor";
                    wifiDetails.put("signalLevel", signalLevel);
                    wifiDetails.put("signalQuality", signalQuality);

                    diagnostics.put("wifiDetails", wifiDetails);
                } else {
                    diagnostics.put("wifiDetails", JSONObject.NULL);
                }

                // Network performance indicators
                JSONObject performance = new JSONObject();
                if (isConnectedToWifi && wifiManager != null) {
                    WifiInfo wifiInfo = wifiManager.getConnectionInfo();
                    int rssi = wifiInfo.getRssi();
                    int linkSpeed = wifiInfo.getLinkSpeed();

                    // Overall network health score (0-100)
                    int healthScore = 0;
                    if (rssi >= -50) healthScore += 40;
                    else if (rssi >= -60) healthScore += 30;
                    else if (rssi >= -70) healthScore += 20;
                    else healthScore += 10;

                    if (linkSpeed >= 100) healthScore += 40;
                    else if (linkSpeed >= 50) healthScore += 30;
                    else if (linkSpeed >= 20) healthScore += 20;
                    else healthScore += 10;

                    if (isConnectedToInternet) healthScore += 20;

                    performance.put("healthScore", healthScore);

                    // Determine status
                    String status;
                    if (healthScore >= 80) status = "excellent";
                    else if (healthScore >= 60) status = "good";
                    else if (healthScore >= 40) status = "fair";
                    else status = "poor";
                    performance.put("status", status);
                } else {
                    performance.put("healthScore", 0);
                    performance.put("status", "disconnected");
                }
                diagnostics.put("performance", performance);

                callbackContext.success(diagnostics);
            } catch (Exception e) {
                Log.e(TAG, "Error getting network diagnostics", e);
                callbackContext.error("Error getting network diagnostics: " + e.getMessage());
            }
        });
    }

    private int getChannelFromFrequency(int frequency) {
        if (frequency >= 2412 && frequency <= 2484) {
            return (frequency - 2412) / 5 + 1;
        } else if (frequency >= 5170 && frequency <= 5825) {
            return (frequency - 5170) / 5 + 34;
        }
        return -1;
    }
}
