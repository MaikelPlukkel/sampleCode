
import UIKit

@objc(MiSnap)
class MiSnap: CDVPlugin, MiSnapViewControllerDelegate, LivenessViewControllerDelegate {
    var callbackId: String = ""
    
    enum CardType: String {
        case passport = "PASSPORT"
        case license = "DRIVER_LICENSE"
        case idFront = "ID_CARD_FRONT"
        case idBack = "ID_CARD_BACK"
    }
    
    var cardType = CardType.passport
    // miSnapCapture is called from JS to initialize MiSnap
    @objc(miSnapCapture:)
    func miSnapCapture(command: CDVInvokedUrlCommand) {
        callbackId = command.callbackId
        
        if let type = CardType(rawValue: "\(command.arguments[0])") {
            cardType = type
        }
       
        let storyboard = UIStoryboard(name: "MiSnapUX1", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "MiSnapSDKViewControllerUX1")
        let misnapViewController:MiSnapSDKViewController = controller as! MiSnapSDKViewController
        
        // Setup delegate, parameters, and transition style
        misnapViewController.delegate = self
        misnapViewController.setupMiSnap(withParams: getparameters(useAutoCapture: true))
        misnapViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.viewController.present(misnapViewController, animated: true, completion: nil)
    }
    
    //Set the parameters for MiSnap
    func getparameters(useAutoCapture:Bool) -> [AnyHashable: Any]  {
        var parameters = MiSnapSDKViewController.defaultParametersForACH()!
        
        switch cardType {
        case .passport:
            parameters = MiSnapSDKViewController.defaultParametersForPassport()
            parameters.setObject("Passport", forKey: kMiSnapShortDescription as NSCopying)
        case .license:
            parameters = MiSnapSDKViewController.defaultParametersForDriversLicense()!
            parameters.setObject("License Front", forKey: kMiSnapShortDescription as NSCopying)
        case .idFront:
            parameters = MiSnapSDKViewController.defaultParametersForIdCardFront()!
            parameters.setObject("id Front", forKey: kMiSnapShortDescription as NSCopying)
            
        case .idBack:
            parameters = MiSnapSDKViewController.defaultParametersForIdCardBack()!
            parameters.setObject("id Back", forKey: kMiSnapShortDescription as NSCopying)
        }
        
        parameters.setObject("0", forKey: kMiSnapTorchMode as NSCopying)
        return parameters as! [AnyHashable : Any]
    }
    
    //Function thats get called when the photo is taken of the object.
    func miSnapFinishedReturningEncodedImage(_ encodedImage: String!, originalImage: UIImage!, andResults results: [AnyHashable : Any]!) {
        var result:[String: Any] = [:]
        result.updateValue(results["MiSnapResultCode"]!, forKey: "miSnapReason")
        result.updateValue(encodedImage, forKey: "encodedImage")
        result.updateValue(results["MiSnapMIBIData"]!, forKey: "mitekBusinessData")
        parseJson(data: result)
        
    }
    
    //gets called when the user cancels the camera for a object
    func miSnapCancelled(withResults results: [AnyHashable : Any]!) {
        sendError(callbackId, message: "User cancelled the action of taking a photo")
    }
    
    // miSnapFacialCapture is called from JS to initialize MiSnapFacial
    @objc(miSnapFacialCapture:)
    func miSnapFacialCapture(command: CDVInvokedUrlCommand) {
        callbackId = command.callbackId
        
        let captureParams:MiSnapLivenessCaptureParameters = MiSnapLivenessCaptureParameters()
        let storyboard = UIStoryboard(name: "FacialCaptureUX", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "LivenessViewController")
        let misnapViewController:LivenessViewController = controller as! LivenessViewController
        misnapViewController.licenseKey = "<Licence Key>"
        
        misnapViewController.delegate = self
        misnapViewController.captureParams = captureParams
        self.viewController.present(misnapViewController, animated: true, completion: nil)
    }
    
    //Function that gets called when the photo is taken of the persons face.
    func livenessCaptureSuccess(_ results: MiSnapLivenessCaptureResults!) {
        var result:[String: Any] = [:]
        result.updateValue(results.score, forKey: "quality")
        result.updateValue(results.encodedImage, forKey: "image")
        result.updateValue(results.uxpData, forKey: "mibiData")
        parseJson(data: result)
    }
    
    //Gets called when the user cancels the camera for face
    func livenessCancelled() {
        sendError(callbackId, message: "User cancelled the action of taking a photo")
    }
    
    //Parse the resultData to json
    func parseJson(data:[String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sendSuccess(callbackId, json: jsonString)
            } else {
                sendError(callbackId, message: "Can't parse json of result data.")
            }
        } catch {
            sendError(callbackId, message: "Can't parse json of result data.")
        }
    }
}

//Go back to Javascript
extension MiSnap {
    
    // Return succes data back to Javascript
    private func sendSuccess(_ callbackId: String, json:String) {
        let result = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: json
        )
        commandDelegate!.send(result, callbackId: callbackId)
    }
    
    // Return error back to Javascript
    private func sendError(_ callbackId: String, message: String, details: Any? = nil) {
        let error = [
            "type": "Error",
            "message": message
            ] as [String : Any]
        
        let result = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: error
        )
        commandDelegate!.send(result, callbackId: callbackId)
    }
}
