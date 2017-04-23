//
//  ViewController.swift
//  Currency converter
//
//  Created by Semyon on 20.02.17.
//  Copyright © 2017 Semyon. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currencies = ["RUB","USD","EUR"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        label.text = "Тут будет курс"
        
        self.retrieveCurrency()
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerTo.delegate = self
        self.pickerFrom.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.requestCurrentCurrencyRate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        if pickerView === pickerTo{
            return self.currenciesExceptBase().count
        }
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo{
            return self.currenciesExceptBase()[row]
        }
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerTo{
            self.pickerTo.reloadAllComponents()
        }
        self.requestCurrentCurrencyRate()
    }
    
    func requestCurrentCurrencyRate() {
        
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency){[weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    if(value == "The Internet connection appears to be offline."){
                        let alertController = UIAlertController(title: "Ошибка", message:
                            "Пожалуйста, подключитесь к интернету.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Окей", style: UIAlertActionStyle.default,handler: nil))
                        
                        self?.present(alertController, animated: true, completion: nil)
                        strongSelf.label.text = "Отсутствует подключение к интернету"
                        self?.activityIndicator.stopAnimating()
                    } else {
                        strongSelf.label.text = "1 \((self?.currencies[(self?.pickerFrom.selectedRow(inComponent: 0))!])! as String) == \(value) \((self?.currencies[(self?.pickerTo.selectedRow(inComponent: 0))!])! as String)"
                        strongSelf.activityIndicator.stopAnimating()
                    }
                    
                }
            })
        }
    }
    
    //Общий метод
    func retrieveCurrency() {
        self.requestCurrency(){[weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    strongSelf.parseCurrencyResponse(data: data)
                    
                }
            }
        }
    }
    
    //Делаем запрос для получения всех валют
    func requestCurrency(parseHandler: @escaping (Data?, Error?) -> Void){
        let url = URL(string: "https://api.fixer.io/latest")!
        
        let dataTask = URLSession.shared.dataTask(with: url){
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        dataTask.resume()
    }
    
    //парсим JSON и получаем все валюты
    func parseCurrencyResponse(data: Data?)->Void{
        var value : String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    for (cur, znach) in rates {
                        if ((cur != "RUB")&&(cur != "USD")&&(cur != "EUR")){
                        currencies.append(cur)
                        }
                    }
                } else {
                    value = "No \"(rates)\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
    }
    
    //Делаем запрос с выбранной валютой
    func requestCurrencyRates(baseCurrency:String, parseHandler: @escaping (Data?, Error?) -> Void){
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url){
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        dataTask.resume()
    }
    
    //парсим JSON и получаем значение
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String)->String{
        var value : String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency]{
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"(rates)\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        return value
    }
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, complection: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency){[weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            complection(string)
        }
    }
    func currenciesExceptBase() -> [String]{
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        pickerFrom.reloadAllComponents()
        return currenciesExceptBase
    }
}
