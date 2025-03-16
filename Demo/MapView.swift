import SwiftUI
import GoogleMaps
import GoogleNavigation

struct MapView: UIViewControllerRepresentable {
    class Coordinator: NSObject {
        var parent: MapView
        var mapView: GMSMapView?  // ✅ Store reference to mapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // ✅ Expose the method to Objective-C & correctly reference mapView
        @objc func startNavigation() {
            guard let mapView = mapView else {
                print("DEBUG: mapView is nil")
                return
            }

            print("DEBUG: Starting navigation...")

            let destinations = [
                GMSNavigationWaypoint(placeID: "ChIJnUYTpNASkFQR_gSty5kyoUk", title: "PCC Natural Market")!,
                GMSNavigationWaypoint(placeID: "ChIJJ326ROcSkFQRBfUzOL2DSbo", title: "Marina Park")!
            ]
            
            mapView.navigator?.setDestinations(destinations) { routeStatus in
                guard routeStatus == .OK else {
                    print("DEBUG: Navigation route status NOT OK.")
                    return
                }
                mapView.navigator?.isGuidanceActive = true
                mapView.locationSimulator?.simulateLocationsAlongExistingRoute()
                mapView.cameraMode = .following
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        let camera = GMSCameraPosition.camera(withLatitude: 47.67, longitude: -122.20, zoom: 14)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true

        context.coordinator.mapView = mapView // ✅ Store mapView in Coordinator

        let companyName = "Ride Sharing Co."
        GMSNavigationServices.showTermsAndConditionsDialogIfNeeded(withCompanyName: companyName) { termsAccepted in
            if termsAccepted {
                mapView.isNavigationEnabled = true
            } else {
                print("DEBUG: User declined Terms & Conditions")
            }
        }
        
        let vc = UIViewController()
        vc.view = mapView

        // ✅ Create a SwiftUI-compatible UIButton inside UIKit
        let navButton = UIButton(frame: CGRect(x: 20, y: 80, width: 200, height: 40))
        navButton.backgroundColor = .blue
        navButton.setTitle("Start Navigation", for: .normal)
        navButton.addTarget(context.coordinator, action: #selector(Coordinator.startNavigation), for: .touchUpInside) // ✅ Fixed target

        vc.view.addSubview(navButton)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
