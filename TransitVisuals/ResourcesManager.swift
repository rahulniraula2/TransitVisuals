
import UIKit

class ResourceManager {
    
    let defautls = UserDefaults.standard
    
    var observation: NSKeyValueObservation?

    deinit {
        observation?.invalidate()
    }
    
    func getHTTPDateformatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
        return formatter
    }
    
    func generateResourceRequest(onlyHead: Bool = false) -> URLRequest {
        var request = URLRequest(url:K.FindGtfsOfflineSourceURL())
        
        if let oldLastModified = self.defautls.string(forKey: "LastModified") {
            request.addValue(oldLastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        
        if let oldEtag = self.defautls.string(forKey: "Etag") {
            request.addValue(oldEtag, forHTTPHeaderField: "If-Match")
        }
        
        if(onlyHead) {
            request.httpMethod = "Head"
        }
        
        return request
    }
    
    func deleteAllFilesFromDocumentsFolder(){
        do{
            let files = try FileManager.default.contentsOfDirectory(
                at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL,
                includingPropertiesForKeys: nil
            )
            try files.forEach { URL in
                try FileManager.default.removeItem(at: URL)
            }
        }catch {
            print("Error deleting files")
        }
    }
    
    func handleDownloadedDataAtUrl(for controller: ViewController, _ localURL : URL, completionHandler: @escaping () -> Void){
        let destinationFileUrl = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL)
        controller.hideLoadingView(hide: true)
        self.deleteAllFilesFromDocumentsFolder()
        do {
            try FileManager().unzipItem(at: localURL, to: destinationFileUrl)
            DispatchQueue.main.async {
                completionHandler()
            }
        } catch (let writeError) {
            print("Error creating a file \(destinationFileUrl) : \(writeError)")
        }
    }
    
    func handleResponse(_ response: HTTPURLResponse){
        if let Etag = response.value(forHTTPHeaderField: "Etag"){
            self.defautls.set(Etag, forKey: "Etag")
        }else{
            print("New Etag not found")
        }
        
        if let lastModified = response.value(forHTTPHeaderField: "Last-Modified"){
            self.defautls.set(lastModified, forKey: "LastModified")
        }else {
            print("New Last modified date not found")
        }
    }
    
    func fetchInitialResources(for controller: ViewController, progressHandler : @escaping (Progress) -> Void, completionHandler: @escaping () -> Void){
        
        let session = URLSession(configuration: .default)
        
        let request = generateResourceRequest(onlyHead: true)
        
        session.downloadTask(with: request, completionHandler: { _, response, err in
            guard let response = response as? HTTPURLResponse else {
                return
            }
            
            let statusCode = response.statusCode
            
            if(statusCode == 304){
                print("Not modified no fetch required")
                completionHandler()
            }else {
                print("New Data found")
                self.presentNewDataAvaliable (for: controller, downloadDataAction: { [self] action in
                    
                    controller.hideLoadingView(hide: false)
                    
                    let dataTask = session.downloadTask(with: self.generateResourceRequest()){ localURL, _, _ in
                        if let localURL = localURL {
                            self.handleResponse(response)
                            self.handleDownloadedDataAtUrl(for: controller, localURL, completionHandler: completionHandler)
                        }
                    }
                
                    observation = dataTask.progress.observe(\.fractionCompleted) { progress, _ in
                        progressHandler(progress)
                    }
                    
                    dataTask.resume()
                    
                }, useStaleDataAction : { action in
                    completionHandler()
                } )
            }
        }).resume()
    }
    
    func presentNewDataAvaliable(for controller: UIViewController, downloadDataAction : @escaping (UIAlertAction)->(Void), useStaleDataAction : @escaping (UIAlertAction)->(Void)) {
        let alert = UIAlertController(title: "New Data Found", message: "Would you like to download new data?", preferredStyle: .actionSheet)
        let downloadAction = UIAlertAction(title: "Download Data", style: .default, handler: downloadDataAction)
        let useStaleAction = UIAlertAction(title: "Use Stale Data", style: .default, handler: useStaleDataAction)
        alert.addAction(downloadAction)
        alert.addAction(useStaleAction)
        DispatchQueue.main.async {
            controller.present(alert, animated: true)
        }
    }
}
