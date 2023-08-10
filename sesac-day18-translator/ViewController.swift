//
//  ViewController.swift
//  sesac-day18-translator
//
//  Created by 박창현 on 2023.08.10.
//

import Alamofire
import SwiftyJSON
import UIKit

//    zh-CN = "중국어 간체",
//    zh-TW = "중국어 번체",
enum Language: String, CaseIterable {
    case ko, ja, hi, en, es, fr, zh_CN, zh_TW, de, pt, vi, id, fa, ar, mm, th, ru, it, unk

    var idx: Int {
        switch self {
        case .ko: return 0
        case .ja: return 1
        case .hi: return 2
        case .en: return 3
        case .es: return 4
        case .fr: return 5
        case .zh_CN: return 6
        case .zh_TW: return 7
        case .de: return 8
        case .pt: return 9
        case .vi: return 10
        case .id: return 11
        case .fa: return 12
        case .ar: return 13
        case .mm: return 14
        case .th: return 15
        case .ru: return 16
        case .it: return 17
        case .unk: return -1
        }
    }

    var getString: String {
        switch self {
        case .ko: return "한국어"
        case .ja: return "일본어"
        case .zh_CN: return "중국어 간체"
        case .zh_TW: return "중국어 번체"
        case .hi: return "힌디어"
        case .en: return "영어"
        case .es: return "스페인어"
        case .fr: return "프랑스어"
        case .de: return "독일어"
        case .pt: return "포르투갈어"
        case .vi: return "베트남어"
        case .id: return "인도네시아어"
        case .fa: return "페르시아어"
        case .ar: return "아랍어"
        case .mm: return "미얀마어"
        case .th: return "태국어"
        case .ru: return "러시아어"
        case .it: return "이탈리아어"
        case .unk: return " 알 수 없음"
        }
    }
}

extension UIButton {
    func setTintColor() {
        tintColor = .systemOrange
    }
}

extension UITextView {
    func setDesign() {
        layer.cornerRadius = 12
        layer.borderColor = CGColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        layer.borderWidth = 2
    }
}

extension UITextField {
    func setDesign() {
        textAlignment = .center
        font = .boldSystemFont(ofSize: 16)
    }
}

class ViewController: UIViewController {
    @IBOutlet var fromLangInput: UITextField!
    @IBOutlet var toLangInput: UITextField!
    @IBOutlet var translateButton: UIButton!
    @IBOutlet var fromText: UITextView!
    @IBOutlet var toText: UITextView!
    @IBOutlet var toLangLabel: UILabel!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var detectLangButton: UIButton!
    let pickerView = UIPickerView()
    var this: (Language?, Language?)
    override func viewDidLoad() {
        super.viewDidLoad()
        fromLangInput.setDesign()
        // Do any additional setup after loading the view.
        toLangInput.isEnabled = false
        toLangInput.text = Language.ko.getString
        this.1 = Language.ko
        toLangInput.setDesign()

        toText.isEditable = false
        fromText.text = ""
        toText.text = ""
        fromText.setDesign()
        toText.setDesign()
        translateButton.setTintColor()
        clearButton.setTintColor()
        detectLangButton.setTintColor()
        pickerView.delegate = self
        pickerView.dataSource = self
        fromLangInput.inputView = pickerView
        dismissPickerView()
    }

    func notFoundLanguage() {
        toLangLabel.text = "언어를 찾을 수 없습니다."
    }

    func foundLanguage(lang: Language) {
        pickerView.selectRow(lang.idx, inComponent: 0, animated: true)
        fromLangInput.text = lang.getString
        this.0 = lang
        endEdit()
    }

    @IBAction func languageDetect(_ sender: UIButton) {
        let url = "https://openapi.naver.com/v1/papago/detectLangs"
        let headers: HTTPHeaders = [
            "X-Naver-Client-Id": env.NAVER_CLIENT_ID.rawValue,
            "X-Naver-Client-Secret": env.NAVER_CLIENT_SECRET.rawValue
        ]
        let parameters: Parameters = ["query": fromText.text ?? ""]
        AF.request(url, method: .post, parameters: parameters, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                guard let code: Language = Language(rawValue: json["langCode"].stringValue.replacingOccurrences(of: "-", with: "_")) else {
                    print("에러가 발생했습니다.")
                    self.notFoundLanguage()
                    break
                }
                if code == .unk {
                    self.notFoundLanguage()
                    break
                }
                self.foundLanguage(lang: code)
            case .failure(let error):
                print(error)
            }
        }
    }

    @IBAction func translateButtonClicked(_ sender: UIButton) {
        guard let source = this.0?.rawValue, let target = this.1?.rawValue else {
            toLangLabel.text = "해당 언어는 번역할 수 없습니다."
            return
        }
        let url = "https://openapi.naver.com/v1/papago/n2mt"
        let header: HTTPHeaders = [
            "X-Naver-Client-Id": env.NAVER_CLIENT_ID.rawValue,
            "X-Naver-Client-Secret": env.NAVER_CLIENT_SECRET.rawValue
        ]
        let params: Parameters = [
            "source": source,
            "target": target,
            "text": fromText.text ?? ""
        ]
        AF.request(url, method: .post, parameters: params, headers: header).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                self.toLangLabel.text = "\(String(describing: Language(rawValue: json["message"]["result"]["srcLangType"].stringValue))) -> \(String(describing: Language(rawValue: json["message"]["result"]["tarLangType"].stringValue))) 번역 결과"
                self.toText.text = json["message"]["result"]["translatedText"].stringValue
            case .failure(let error):
                print(error)
            }
        }
    }

    @IBAction func clearButtonClicked(_ sender: UIButton) {}
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Language.allCases.count - 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Language.allCases[row].getString
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        fromLangInput.text = Language.allCases[row].getString
        this.0 = Language.allCases[row]
    }

    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let button = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(endEdit))
        toolBar.setItems([flexibleSpace, button], animated: true)
        toolBar.isUserInteractionEnabled = true
        fromLangInput.inputAccessoryView = toolBar
    }

    @objc func endEdit() {
        view.endEditing(true)
    }
}
