#include "ofApp.h"

// Visual helpers (not required).
// Change below to match your beacon/colours- otherwise they will appear white. id's are beacon's major id.
const int ids[3] = {32492, 42365, 40448};
// blue, purple, green (color of estimotes associated with major ids)
const ofColor colors[3] = {ofColor(0,127,255),ofColor(127,0,255),ofColor(127,255,127)};


ofColor getColor(int majorId) {
    for(int i = 0; i < 3; i++) if(majorId == ids[i]) return(colors[i]);
    return ofColor();
}

// tested on ipad - enable retina in main.mm if working on iphone
//--------------------------------------------------------------
void ofApp::setup(){	

    //ofSetFrameRate(60);
    ofSetVerticalSync(true);
    ofEnableAlphaBlending();
    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    estimote = new ofxEstimote();
    estimote->setup();

    
    // display options
    origin.set(ofGetWidth()*.5, 100); // the device origin
    distanceRange = 15.0; // meters?
    beaconRadius = 20;
}

//--------------------------------------------------------------
void ofApp::update(){

}

// displaying the beacons in a linear 1D proximity map
//--------------------------------------------------------------
void ofApp::draw(){
    
    
    // draw a label which has the range in meters + line
    ofSetColor(0, 50);
    ofLine(origin.x, origin.y, origin.x, ofGetHeight()-origin.y);
    ofDrawBitmapStringHighlight(ofToString(distanceRange) + " meters or so?", int(origin.x)-50, int(ofGetHeight() - origin.y));
    ofSetColor(0);
    
    
    
    // draw the beacons relative to a device/origin - grey rectangle
    ofPushMatrix();
    ofPushStyle();
    ofSetColor(50);
    float s = 50;
    ofTranslate(int(origin.x-(s*.5)), int(origin.y-(s*.5)));
    ofRect(0,0, s, s);
    ofDrawBitmapStringHighlight("iDevice", 5, 5);//, ofColor(255,0,255));
    ofPopStyle();
    ofPopMatrix();
    
   
    
    vector<ofxEstimoteData>& beacons = estimote->getBeaconsRef();
    for(int i = 0; i < beacons.size(); i++) {
        
        // draw the beacons in advertising mode whose rssi signal is not 0
        // a filled coloured circle represents the beacon, outline represents the raw rssi signal
        if(!beacons[i].connectivityMode && beacons[i].rssi != 0) {
            float nDistance = beacons[i].distance / distanceRange; //
            float posY = ofMap(nDistance, 0.0, 1.0, origin.y, ofGetHeight()-origin.y);
            ofPushMatrix();
            ofPushStyle();
            ofTranslate(int(origin.x), int(posY));
            ofNoFill();
            ofSetColor(255,100);
            ofCircle(0, 0, ofMap(beacons[i].rssi, -30, -100, 200, 25)); // -30 = close/larger, -100 = far/smaller
            ofFill();
            ofSetColor(getColor(beacons[i].major)); // get beacon color from major id
            ofCircle(0, 0, beaconRadius);
            ofSetColor(0);
            ofDrawBitmapString(estimote->beaconDataToString(beacons[i]), 5, 5);// draw the beacons info
            ofPopStyle();
            ofPopMatrix();
        }

    }
    
    // draw the single beacon in connectivity mode if activated, in top left somewhere
    if(estimote->isBeaconActivated()) {
        ofxEstimoteData& activatedBeacon = estimote->getActivatedBeacon();
        if(activatedBeacon.connectivityMode) {
            ofPushMatrix();
            ofPushStyle();
            ofTranslate(20, 100);
            ofColor beaconClr = getColor(activatedBeacon.major);
            ofDrawBitmapStringHighlight("CONNECTIVITY MODE ACTIVATED FOR BEACON:\n" + estimote->beaconDataToString(activatedBeacon), 5, 5, beaconClr, ofColor::black);
            ofPopStyle();
            ofPopMatrix();
        }
    }

	
    stringstream info;
    info << "Beacons detected: " << beacons.size() << endl;
    info << "> TAP BEACON FOR CONNECTIVITY MODE" << endl;
    info << "> DOUBLE TAP TO DISCONNECT";
    ofDrawBitmapStringHighlight(info.str(), 20, 20);
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

    
    vector<ofxEstimoteData>& beacons = estimote->getBeaconsRef();
    for (int i = 0; i < beacons.size(); i++) {
        
        float nDistance = beacons[i].distance / distanceRange; //
        float posY = ofMap(nDistance, 0.0, 1.0, origin.y, ofGetHeight()-origin.y);
        float posX = origin.x;
        
        if(touch.x > posX - beaconRadius && touch.x < posX + beaconRadius && touch.y > posY - beaconRadius && touch.y < posY + beaconRadius) {
            // touched- set this beacon to connectivity mode
            ofLog() << "Touched beacon " <<  beacons[i].major;
            estimote->enableBeaconConnectivityMode(beacons[i].major, beacons[i].minor);
        }
    }
    
    
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

    // disconnect the active beacon and set back to default advertising mode
    estimote->disableBeaconConnectivityMode();
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}


