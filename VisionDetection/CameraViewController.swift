//
//  CameraViewController.swift
//  VisionDetection
//
//  Created by zhuziyang on 2024/10/16.
//  Copyright © 2024 Willjay. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    
    // 按钮点击计数器
    var buttonClickCounts: [UIButton: Int] = [:]
    // 记录所有按钮
    var buttons: [UIButton] = []
    
    // 记录点击的当前按钮，用于在拍照时标识来源
    var currentButton: UIButton?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // 设置相机捕捉会话
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("无法访问相机")
            return
        }
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("无法访问前置相机")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 配置输出
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            // 显示相机的预览层
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)

            // 启动相机
            // 在后台线程启动相机捕获会话
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("相机不可用: \(error)")
        }
        
//        // 添加拍摄按钮
//        let captureButton = UIButton(type: .system)
//        captureButton.setTitle("拍摄", for: .normal)
//        captureButton.frame = CGRect(x: 100, y: view.frame.height - 100, width: 200, height: 50)
//        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
//        view.addSubview(captureButton)
        createButtons()
    }
    
    func createButtons(){
        // 这里是屏幕九个校准点的位置数据
        let positions = [
            CGPoint(x: 50, y: 100),   // 左上
            CGPoint(x: 50, y: view.frame.height / 2),  // 左中
            CGPoint(x: 50, y: view.frame.height - 100),  // 左下
            CGPoint(x: view.frame.width - 50, y: 100),  // 右上
            CGPoint(x: view.frame.width - 50, y: view.frame.height / 2),  // 右中
            CGPoint(x: view.frame.width - 50, y: view.frame.height - 100),  // 右下
            CGPoint(x: view.frame.width / 2, y: 100),  // 中上
            CGPoint(x: view.frame.width / 2, y: view.frame.height - 100),  // 中下
            CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)  // 中中
        ]
        
        // 标签数组，标识按钮的位置
        let tags = ["left_top", "left_middle", "left_bottom", "right_top", "right_middle", "right_bottom", "center_top", "center_bottom", "center_center"]
        
        for (index, position) in positions.enumerated() {
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            button.layer.cornerRadius = 20
            button.backgroundColor = .white
            button.center = position
//            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            
            button.tag = index
            button.accessibilityLabel = tags[index]
            
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            
            // 初始化点击次数为 0
            buttonClickCounts[button] = 0
            
            view.addSubview(button)
            buttons.append(button)
        }
    }
    
    // 每次点击按钮
    @objc func buttonTapped(_ sender: UIButton) {
        // 记录按钮点击次数
        currentButton = sender
        
        if let count = buttonClickCounts[sender] {
            buttonClickCounts[sender] = count + 1
            print("按钮点击次数: \(buttonClickCounts[sender]!) 来自按钮: \(sender.accessibilityLabel!)")
            
            // 拍摄照片
            capturePhoto()

            // 如果按钮点击次数达到 3 次，移除按钮
            if buttonClickCounts[sender]! >= 3 {
                sender.removeFromSuperview()
                buttons.removeAll { $0 == sender }

                // 检查是否所有按钮都已消失
                if buttons.isEmpty {
                    showDataCollectionComplete()
                }
            }
        }
    }
    

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // 所有按钮消失后提示并返回主界面
    func showDataCollectionComplete() {
        let alert = UIAlertController(title: "完成", message: "数据采集完成", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { _ in
            // 返回主界面
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    // 停止会话以释放资源
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let capturedImage = UIImage(data: imageData)
        
        // 获取当前按钮的位置标识（如"left_top", "center_center"）
        let buttonTag = currentButton?.accessibilityLabel ?? "unknown"
        
        // 生成带有按钮位置信息的文件名
        let fileName = "photo_\(buttonTag)_\(UUID().uuidString).jpg"
        print("保存图片的文件名: \(fileName)")
        
        // 保存图片到相册
//        UIImageWriteToSavedPhotosAlbum(capturedImage!, nil, nil, nil)
        // 保存到自定义目录 "images/cali"
        saveImageToCustomDirectory(image: capturedImage!, fileName: fileName)
        print("图片已保存")
    }
    
    // 保存图片到自定义目录
    func saveImageToCustomDirectory(image: UIImage, fileName: String) {
        // 获取沙盒中的 Document 目录
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("无法访问文档目录")
            return
        }
        
        // 创建自定义目录 "images/cali"
        let customDir = documentsDirectory.appendingPathComponent("images/cali")
        if !fileManager.fileExists(atPath: customDir.path) {
            do {
                try fileManager.createDirectory(at: customDir, withIntermediateDirectories: true, attributes: nil)
                print("创建目录: \(customDir.path)")
            } catch {
                print("创建目录失败: \(error)")
            }
        }

        // 保存文件到自定义目录
        let fileURL = customDir.appendingPathComponent(fileName)
        if let imageData =  UIImageJPEGRepresentation(image, 1.0) {
            do {
                try imageData.write(to: fileURL)
                print("图片已保存到: \(fileURL.path)")
            } catch {
                print("保存图片失败: \(error)")
            }
        }
    }
}
