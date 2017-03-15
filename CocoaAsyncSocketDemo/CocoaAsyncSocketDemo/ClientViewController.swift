//
//  ClientViewController.swift
//  CocoaAsyncSocketClient
//
//  Created by Laughing on 2017/3/14.
//  Copyright © 2017年 Laughing. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ClientViewController: UIViewController {
    
    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    
    
    

    var messages:[String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.messageTableView.reloadData()
            }
        }
    }
    
    
    let tag = 100
    var socket: GCDAsyncSocket?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        hostField.text = "192.168.16.72"
        portField.text = "8080"
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        // 创建 socket
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.global())
    }
    
}


// MARK: - 事件处理
extension ClientViewController {
    
    @IBAction func clean(_ sender: Any) {
        messages.removeAll()
    }
    
    @IBAction func send(_ sender: Any) {
        
        if messageField.text == nil || messageField.text == ""{
         
            print(#function,"\n --: desc: ", "发送的信息不能为空")
            return
        }
        
        let msgData =  ("Client(\(tag)):" + messageField.text!).data(using: .utf8)
        socket?.write(msgData!, withTimeout: -1, tag: tag)
        messages.append( String(data: msgData!, encoding: .utf8)! )
    }
    
    @IBAction func connect(_ sender: Any) {
        
        if socket!.isConnected {
            
            print(#function,"\n --: desc: ", "socket 已经连接！")
            return
        }
        
        
        do {
            let port = UInt16((portField.text! as NSString).intValue)
            try socket?.connect(toHost: hostField.text!, onPort:port)
            
            let mes = "连接:" + hostField.text! + ": \(port)"
            messages.append(mes)
            
        } catch {
            print(error)
        }
    }
}

// MARK: GCDAsyncSocketDelegate
extension ClientViewController : GCDAsyncSocketDelegate {
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print(#function,"\n --: sock: ", sock, "\n --: desc: ", "sock 断开连接", "\n --: Error:", err ?? "错误为 nil")
         sock.readData(withTimeout: -1, tag: tag)
    }
    
    //  和服务器创建连接完成
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        
        print(#function,"\n --: sock: ", sock, "\n --: desc: ", "sock 连接成功！", "\n --: host: ", host, "\n --: port: ", port)
        sock.readData(withTimeout: -1, tag: tag)
        self.messages.append("连接主机成功！")
    }
    
    // 数据接收完成
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        let receiverStr = String(data: data, encoding: .utf8)
        
        // 通知对方接受数据完成，可以进行下次的数据的接收
        sock.readData(withTimeout: -1, tag: tag)
        
        self.messages.append(receiverStr!)
    }
    
    // 数据发送成功
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
        // 数据发送完成后一定要调用下读数据的方法
        // 通知对方接收数据
         sock.readData(withTimeout: -1, tag: tag)
        
        print(#function,"\n --: sock: ", sock, "\n --: desc: ", "sock 数据发送成功！", "\n --: tag: ", tag)

        
        DispatchQueue.main.async {
            self.messageField.text = nil
        }
    }
}

extension ClientViewController : UITableViewDelegate {
    
}

extension ClientViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = messages[indexPath.row]
        return cell!
    }
}
