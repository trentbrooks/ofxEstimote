
#include "ofxEstimote.h"

// OF
//--------------------------------------------------------------
ofxEstimote::ofxEstimote(){

    ready = false;
    beaconActivated = false;
    selectedBeacon = nil;
}

ofxEstimote::~ofxEstimote(){

    if(ready) {
        [estimoteDelegate dealloc];
        estimoteDelegate = nil;
        [beaconManager stopMonitoringForRegion:region];
        beaconManager.delegate = nil;
        [beaconManager dealloc];
        beaconManager = nil;
        [region dealloc];
        region = nil;
    }
}

void ofxEstimote::setup() {

    // setup estimote beacon manager + delegate
    estimoteDelegate = [[ofxEstimoteDelegate alloc] init:	this ];
    beaconManager = [[ESTBeaconManager alloc] init];
    [beaconManager setDelegate:estimoteDelegate];
    
    // create sample region object (you can additionaly pass major / minor values)
    region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                  identifier:@"EstimoteSampleRegion"];
    
    
    // start looking for estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    [beaconManager startRangingBeaconsInRegion:region];
    
    ready = true;

}

bool ofxEstimote::isReady() {
    return ready;
}

void ofxEstimote::enableBeaconConnectivityMode(int majorId, int minorId) {
    
    // only 1 beacon at a time can be in connectivity mode
    // wait for the callback from selectedBeacon before marking beacon as activated
    disableBeaconConnectivityMode();
    for(int i = 0; i < beacons.size(); i++) {
        if(beacons[i].major == majorId && beacons[i].minor == minorId) {
            selectedBeacon = beacons[i].beacon;
            [selectedBeacon retain];
            [selectedBeacon setDelegate:estimoteDelegate];
            [selectedBeacon connectToBeacon];
            return;
        }
    }
}

void ofxEstimote::disableBeaconConnectivityMode() {
    
    // no need to do anything with major and minor here - just disconnect the active one
    if(selectedBeacon) {
        if(selectedBeacon.isConnected) {
            NSLog(@"Disconnecting beacon: %@ %@", selectedBeacon.major, selectedBeacon.minor);
            selectedBeacon.delegate = nil;
            [selectedBeacon disconnectBeacon];
            [selectedBeacon release];
            beaconActivated = false;
        }
    }
}

ofxEstimoteData ofxEstimote::getBeaconData(ESTBeacon* from) {
    
    ofxEstimoteData data;
    data.proximityUUID = convertNSString(from.proximityUUID.UUIDString);
    data.major = from.major.intValue;
    data.minor = from.minor.intValue;
    data.rssi = from.rssi;
    data.distance = from.distance.floatValue;
    data.proximityZone = from.proximity;
    data.connectivityMode = from.isConnected;
    if(data.connectivityMode) {
        
        // unique to connectivity mode
        data.macAddress = convertNSString(from.macAddress);
        data.power = from.power.charValue;// intValue;
        data.battery = from.batteryLevel.intValue;
        data.advInterval = from.advInterval.intValue;
        data.measurePower = from.measuredPower.floatValue;
    }
    data.beacon = from; // save reference to the ESTBeacon
    return data;
}

void ofxEstimote::onBeaconsAdvertisingMode(NSArray *estBeacons) {
    
    // convert NSArray beacons to vector
    beacons.clear();
    for (ESTBeacon* cBeacon in estBeacons) {
        beacons.push_back(getBeaconData(cBeacon));
    }
}

void ofxEstimote::onBeaconConnectivityMode(ESTBeacon* cBeacon) {
    
    activatedBeacon = getBeaconData(cBeacon);
    beaconActivated = true;
    
    // TODO: add methods for changing proximity id, major, minor, updating firmware etc.
    // can currently do this with estimotes own app https://itunes.apple.com/au/app/estimote-virtual-beacon/id686915066 - so not really important.
    ofLog() << "Beacon is in connectivity mode- can now read more data values";
    
    // not required...
    readSelectedBeaconConfiguration();
}

// call this after writing any values to get the new updated values.
void ofxEstimote::readSelectedBeaconConfiguration() {
    
    if(!beaconActivated) return;
    
    // Methods for reading beacon configuration - note this is already saved in activatedBeacon.
    // for some reason power is incorrect/not in db until this block is called
    [selectedBeacon readBeaconPowerWithCompletion:^(ESTBeaconPower value, NSError* error) {
        NSLog(@"what is power level: %d", value );
        activatedBeacon.power = value;
    }];
    
    [selectedBeacon readBeaconAdvIntervalWithCompletion:^(unsigned short value, NSError* error) {
        activatedBeacon.advInterval = value;
    }];
    
    [selectedBeacon readBeaconProximityUUIDWithCompletion:^(NSString* value, NSError* error) {
        activatedBeacon.proximityUUID = convertNSString(value);
    }];
    
    [selectedBeacon readBeaconMajorWithCompletion:^(unsigned short value, NSError* error) {
        activatedBeacon.major = value;
    }];
    
    [selectedBeacon readBeaconMinorWithCompletion:^(unsigned short value, NSError* error) {
        activatedBeacon.minor = value;
    }];
    
    [selectedBeacon readBeaconBatteryWithCompletion:^(unsigned short value, NSError* error) {
        activatedBeacon.battery = value;
    }];
    
    [selectedBeacon checkFirmwareUpdateWithCompletion:^(BOOL updateAvailable, ESTBeaconUpdateInfo* updateInfo, NSError* error) {
        if(updateAvailable) {
            NSLog(@"Firmware update is available for this beacon: %@", [updateInfo currentFirmwareVersion]);
        }
        
        NSLog(@"Firmware update is available for this beacon: %@", [updateInfo currentFirmwareVersion]);
    }];
}



bool ofxEstimote::isBeaconActivated() {
    return beaconActivated;
}

vector<ofxEstimoteData>& ofxEstimote::getBeaconsRef() {
    return beacons;
}

ofxEstimoteData& ofxEstimote::getActivatedBeacon() {
    return activatedBeacon;
}

string ofxEstimote::convertNSString(NSString* ns) {
    
    if(!ns) return "";    
    return string([ns UTF8String]);
}

string ofxEstimote::beaconDataToString(ofxEstimoteData& data) {
    
    stringstream s;
    s << "pid: " << data.proximityUUID << endl;
    s << "maj: " << data.major << endl;
    s << "min: " << data.minor << endl;
    s << "rssi: " << data.rssi << endl;
    s << "dist: " << data.distance << endl;
    s << "zone: " << data.proximityZone << endl;
    if(data.connectivityMode) {
        s << "con: " << data.connectivityMode << endl;
        s << "mac: " << data.macAddress << endl;
        s << "pwr: " << data.power << endl;
        s << "mpwr: " << data.measurePower << endl;
        s << "bat: " << data.battery << endl;
        s << "adv: " << data.advInterval << endl;
    }
    
    return s.str();
}



// OBJC
//--------------------------------------------------------------
@implementation ofxEstimoteDelegate



//--------------------------------------------------------------
- (id) init :(ofxEstimote *)estCpp {
    
	if(self = [super init])	{
		NSLog(@"ofxEstimoteDelegate initiated");
        
        // ref to OF instance
        estimoteCpp = estCpp;
	}
	return self;
}

- (void) dealloc {

    NSLog(@"ofxEstimoteDelegate dealloc");
    estimoteCpp = nil;
    [super dealloc];
}



#pragma mark - ESTBeaconManagerDelegate Implementation
-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    //NSLog(@"Beacon manager callback %d", [beacons count]);

    estimoteCpp->onBeaconsAdvertisingMode(beacons); // check this after loop
    //for (ESTBeacon* cBeacon in beacons) {    }
    
}

-(void)beaconManager:(ESTBeaconManager *)manager
rangingBeaconsDidFailForRegion:(ESTBeaconRegion *)region
           withError:(NSError *)error
{
    NSLog(@"Failed to find beacons in region");
}


// TODO: implement methods for setting proximity id/major/minor/etc
#pragma mark - Individual estimotes delegate
- (void)beaconConnectionDidFail:(ESTBeacon*)beacon withError:(NSError*)error {
    
    NSLog(@"Failed to connect to beacon %@ %@", beacon.major, beacon.minor);
}

- (void)beaconConnectionDidSucceeded:(ESTBeacon*)beacon {
    
    NSLog(@"Connected to beacon %@ %@", beacon.major, beacon.minor);
    estimoteCpp->onBeaconConnectivityMode(beacon);
    
    /*if(selectedBeacon == beacon) {
        NSLog(@" yes it's the same beacon");
    }
    estimoteCpp->copyBeaconData(beacon, estimoteCpp->selectedBeacon);
    
    // completion blocks? don't know why i can't just call the properties instead
    [beacon readBeaconAdvIntervalWithCompletion:^(unsigned short val, NSError* error) {
        //NSLog(@"Read adv interval: %hi", val);
        estimoteCpp->selectedBeacon->advInterval = val;
    }];
    
    [beacon readBeaconPowerWithCompletion:^(ESTBeaconPower val, NSError* error) {        
        //NSLog(@"Read power level: %d", val);
        estimoteCpp->selectedBeacon->power = val;
    }];
    
    [beacon readBeaconBatteryWithCompletion:^(unsigned short val, NSError* error) {
        //NSLog(@"Read battery: %hi", val);
        estimoteCpp->selectedBeacon->battery = val;
    }];*/
    
}

- (void)beaconDidDisconnect:(ESTBeacon*)beacon withError:(NSError*)error {
    
    NSLog(@"Disconnected beacon %@ %@", beacon.major, beacon.minor);
}

@end