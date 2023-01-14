
import UIKit

class ResourceManager {
    
    let defautls = UserDefaults.standard
    
    var observation: NSKeyValueObservation?
    
    var delegate : ResourceManagerDelegate?
    
    let dataManagerInitializer = DataMangagerInitializer()
    
    var fractionComplete = 0.0
    
    init() {
        dataManagerInitializer.delegate = self
    }

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
        
        if(onlyHead) {
            request.httpMethod = "Head"
            
            if let oldLastModified = self.defautls.string(forKey: "LastModified") {
                request.addValue(oldLastModified, forHTTPHeaderField: "If-Modified-Since")
            }
            
            if let oldEtag = self.defautls.string(forKey: "Etag") {
                request.addValue(oldEtag, forHTTPHeaderField: "If-None-Match")
            }
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
    
    func handleDownloadedDataAtUrl(_ localURL : URL){
        let destinationFileUrl = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL)
        self.deleteAllFilesFromDocumentsFolder()
        do {
            try FileManager().unzipItem(at: localURL, to: destinationFileUrl)
            self.dataManagerInitializer.loadOnly()
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
    
    func fetchInitialResources(for controlkler: ViewController){
        //uncomment to force reload data
        self.defautls.set("e", forKey: "Etag")
        
        let session = URLSession(configuration: .default)
        
        let request = generateResourceRequest(onlyHead: true)
        
        session.downloadTask(with: request, completionHandler: { _, response, err in
            
            if let _ = err {
                self.delegate?.resourceManager(self, didFinishLoadingData: Void())
            }
            
            guard let response = response as? HTTPURLResponse else {
                return
            }
            let statusCode = response.statusCode
            
            if(statusCode == 304){
                print("Not modified no fetch required")
                self.delegate?.resourceManager(self, didFinishLoadingData: Void())
            }else {
                print("New Data found")
                self.presentNewDataAvaliable (downloadDataAction: { [self] action in
                    self.dataManagerInitializer.deleteAllEntities()
                    self.delegate?.resourceManager(self, updatedLoadingStatus: true)
                    let dataTask = session.downloadTask(with: self.generateResourceRequest()){ localURL, _, _ in
                        if let localURL = localURL {
                            self.handleResponse(response)
                            self.handleDownloadedDataAtUrl(localURL)
                        }
                    }
                
                    observation = dataTask.progress.observe(\.fractionCompleted) { progress, _ in
                        self.fractionComplete = progress.fractionCompleted
                    }
                    
                    dataTask.resume()
                    
                }, useStaleDataAction : { action in
                    self.delegate?.resourceManager(self, didFinishLoadingData: Void())
                } )
            }
        }).resume()
    }
    
    func presentNewDataAvaliable(downloadDataAction : @escaping (UIAlertAction)->(Void), useStaleDataAction : @escaping (UIAlertAction)->(Void)) {
        let alert = UIAlertController(title: "New Data Found", message: "Would you like to download new data?", preferredStyle: .actionSheet)
        let downloadAction = UIAlertAction(title: "Download Data", style: .default, handler: downloadDataAction)
        let useStaleAction = UIAlertAction(title: "Use Stale Data", style: .default, handler: useStaleDataAction)
        alert.addAction(downloadAction)
        alert.addAction(useStaleAction)
        self.delegate?.resourceManager(self, newDataAvaliable: alert)
    }
}

protocol ResourceManagerDelegate {
    func resourceManager(_ resourceManager: ResourceManager, didFinishLoadingData: Void)
    
    func resourceManager(_ resourceManager: ResourceManager, updatedProgress: Double)
    
    func resourceManager(_ resourceManager: ResourceManager, newDataAvaliable alert: UIAlertController)
    
    func resourceManager(_ resourceManager: ResourceManager, updatedLoadingStatus loading: Bool)
}

extension ResourceManager: DataMangagerInitializerDelegate {
    func DataMangager(_ dataManager: DataMangagerInitializer, didFinishLoadingCoreData: Void) {
        self.delegate?.resourceManager(self, updatedLoadingStatus: false)
        self.delegate?.resourceManager(self, didFinishLoadingData: didFinishLoadingCoreData)
    }
    
    func DataMangager(_ dataManager: DataMangagerInitializer, updatedProgress: Double) {
        self.delegate?.resourceManager(self, updatedProgress: (self.fractionComplete * 0.3) + (updatedProgress*0.70))
    }
}
