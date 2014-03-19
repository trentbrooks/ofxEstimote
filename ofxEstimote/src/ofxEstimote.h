#pragma  once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#import <ESTBeaconManager.h>

/* ofxEstimote.
 - have to add CoreBluetooth framework to build phases link binary with library
 - had to change deployment target to ios 7 for app + iOS+OFLib
 - had to switch project's "C++ standard library" from "Compiler Default" to "libstdc++"
 - drag and drop libEstimoteSDK.a into project
 */


class ofxEstimote;

// OBJC DELEGATE
//--------------------------------------------------------------
@interface ofxEstimoteDelegate : NSObject<ESTBeaconManagerDelegate, ESTBeaconDelegate>
{
    // giving the delegate access to the OF c++ implementation as well
    ofxEstimote* estimoteCpp;
}

- (id) init:(ofxEstimote *)estCpp;


@end


/* ofxEstimoteData.
 - of style wrapper for the basic data types inside ESTBeacon
 - http://estimote.github.io/iOS-SDK/Classes/ESTBeacon.html
 */
class ofxEstimoteData {
public:
    // advertising mode (default)
    string proximityUUID;
    int major;
    int minor;
    int rssi; // signal strength in decibels
    float distance; // distance between phone and beacon based on rssi and measured power. In meters i think.
    int proximityZone; // 0=unknown,1=immediate,2=near,3=far
    
    // connectivity mode - values are not continuosly updated in connectivity mode, and only 1 beacon can be in connectivity mode at a time.
    bool connectivityMode;
    string macAddress;
    int power; // power of signal in dBm
    int battery; // battery strength in %
    int advInterval; // advertising interval of the beacon in ms. Value change from 50ms to 2000ms
    float measurePower; // rssi value measured from 1m
    
    ESTBeacon* beacon; // reference to the beacon itself
    
    ofxEstimoteData() {
        connectivityMode = false;
        macAddress = "";
        power = battery = advInterval = measurePower = 0;
    };
};



// C++ OF
//--------------------------------------------------------------
class ofxEstimote {
public:
    
    ofxEstimote();
    virtual ~ofxEstimote();

    void setup();
    bool isReady();
    
    // ios delegate
    ofxEstimoteDelegate* estimoteDelegate;
    void onBeaconsAdvertisingMode(NSArray *beacons); // called for beacons in advertising mode
    void onBeaconConnectivityMode(ESTBeacon* cBeacon); // called when a single beacon is activated (in connectivity mode)
    
    vector<ofxEstimoteData>& getBeaconsRef();
    ofxEstimoteData& getActivatedBeacon();
    
    // allows retrieval of battery level, advertising interval, etc for a single beacon
    void enableBeaconConnectivityMode(int majorId, int minorId);
    void disableBeaconConnectivityMode();
    bool isBeaconActivated();
    
    string beaconDataToString(ofxEstimoteData& data);
        
protected:
    
    bool ready;
    ESTBeaconManager* beaconManager;
    ESTBeaconRegion* region;
    ofxEstimoteData getBeaconData(ESTBeacon* from);
    ESTBeacon* selectedBeacon; // once a beacon is selected, wait for connection callback to set activatedBeacon
    void readSelectedBeaconConfiguration();
    ofxEstimoteData activatedBeacon;
    bool beaconActivated;
    string convertNSString(NSString* ns);
    vector<ofxEstimoteData> beacons;
};

