//
//  ServiceViewController.swift
//  CocoaAsyncSocketClient
//
//  Created by Laughing on 2017/3/14.
//  Copyright © 2017年 Laughing. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ServiceViewController: UIViewController {

    @IBOutlet weak var portField: UITextField!
    var serviceSocket: GCDAsyncSocket?
    var newServiceSocket: GCDAsyncSocket?
    var msgs : [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    @IBOutlet weak var msgField: UITextField!
    
    
    @IBAction func sendBtnClick(_ sender: Any) {
        
        if msgField.text?.characters.count == 0 {
            print(#function, "\n--: desc: ", "请输入你要发送的内容！")
        } else {
            
            let msgData =  ("Client(\(tag)):" + msgField.text!).data(using: .utf8)
            newServiceSocket!.write(msgData!, withTimeout: -1, tag: tag)
        }
    }
    
    
    
    @IBAction func clearBtnClick(_ sender: Any) {
        msgs.removeAll()
    }
    
    @IBAction func startListenPort(_ sender: Any) {
        do {
            let port = UInt16((portField.text! as NSString).intValue)
            // 监听本机的 12345 端口
            try serviceSocket?.accept(onPort: port)
            msgs.append("开始监听本机8080 端口")
            print(#function, "\n--: desc: ", "开始监听本机\(portField.text) 端口", "\n--: port:", port)
        } catch {
            print(#function, "\n--: desc: ", "监听本机\(portField.text) 端口失败！", "\n--: error: ", error)
        }
    }

    @IBOutlet weak var tableView: UITableView!
    
    let tag = 101;
    override func viewDidLoad() {
        super.viewDidLoad()

        serviceSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.global())
        portField.text = "8080";
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tableView.endEditing(true)
    }
}

extension ServiceViewController: UITableViewDelegate {

}

extension ServiceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgs.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
        
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = msgs[indexPath.row]
        return cell!
    }
}

// MARK: 服务
extension ServiceViewController : GCDAsyncSocketDelegate {

    // 已经接受新的 socket 连接
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        print(#function, "\n--: socket: ", sock, "\n--: desc: ", "有新的 sock 连接！", "\n--: newSocket: ", newSocket)
        
        newServiceSocket = newSocket
        
        newSocket.write("1234567890".data(using: .utf8)!, withTimeout: -1, tag: tag)
        
        // 准备开始接收数据
        newSocket.readData(withTimeout: -1, tag: tag)
    }
    
    
    // 数据接收完成
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        let receiverStr = String(data: data, encoding: .utf8)
        msgs.append(receiverStr!)


          sock.readData(withTimeout: -1, tag: tag)
        
    
        print(#function, "\n--: socket: ", sock, "\n--: desc: ", "数据接收完成", "\n--: dataStr: ", receiverStr!, "\n--: tag: ", tag )
        
    
    }
    
    
    // 数据发送成功
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
//        sock.readData(withTimeout: -1, tag: tag)
        
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("sock 连接已经断开！")
        msgs.append("sock 连接已经断开！")
    }
}
