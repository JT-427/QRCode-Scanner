//
//  ScannerViewController.swift
//  QRCode Scanner
//
//  Created by JT on 2022/6/9.
//

import UIKit
import AVFoundation
var activity_id_choosed = ""
let domainName = "https://"
//let domainName = "https://f79a-123-194-158-79.ngrok.io"
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var activityButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadActivities()
        scannerView.layer.cornerRadius = CGFloat(20.0)
        scannerView.clipsToBounds = true
        
//        view.backgroundColor = UIColor.black
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scannerView.layer.bounds
        
        previewLayer.videoGravity = .resizeAspectFill
        scannerView.layer.addSublayer(previewLayer)
        stackView.addSubview(scannerView)

        captureSession.startRunning()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        let request = Request(domainName: domainName + "/rollcall", qrcode: code)
        var outputMessage: String?
        request.sendRequest(){data,error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(RollcallResponseResult.self, from: data)
                    if response.result == "success"{
                        let responseSuccessful = try decoder.decode(RollcallResponseSuccess.self, from: data)
                        outputMessage = responseSuccessful.message.name + " / " + responseSuccessful.message.group + "\n\n" + responseSuccessful.message.message
                        
                        DispatchQueue.main.async {
                            self.outputLabel.text = outputMessage!
                        }
                    }else{
                        let responseFailed = try decoder.decode(RollcallResponseFail.self, from: data)
                        DispatchQueue.main.async {
                            self.outputLabel.text = responseFailed.message
                        }
                    }
                    
                } catch  {
                    print(error)
                }
            }
        }
        captureSession.startRunning()
    }

    func loadActivities(){
        self.activityButton.isEnabled = false
        self.activityButton.setTitle("請稍候...", for: .disabled)
        let activities = GetActivities(domainName: domainName)
        activities.sendRequest(){data,error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ActivityResponse.self, from: data)
                    if response.result == "success"{
                        var activities = [String: String]()
                        var buttonMenuChildren = [UIAction]()
                        for i in response.activities!{
                            buttonMenuChildren.append(
                                UIAction(title: i.activity_name + " " + i.start_time, handler: { action in
                                    self.activityButton.setTitle(i.activity_name + " " + i.start_time, for: .normal)
                                    activity_id_choosed = i.activity_id
                                })
                            )
                            activities[i.activity_id] = i.activity_name + " " + i.start_time
                        }
                        DispatchQueue.main.async {
                            self.activityButton.menu = UIMenu(children:buttonMenuChildren)
                            self.activityButton.isEnabled = true
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.activityButton.setTitle("尚無聚會", for: .disabled)
                        }
                    }
                } catch  {
                    print(error)
                }
            }
        }
    }
    
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func refresh(_ sender: Any) {
        loadActivities()
    }
    
}
