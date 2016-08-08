//
//  OddSDKTests.swift
//  OddSDKTests
//
//  Created by Patrick McConnell on 4/22/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//
// http://masilotti.com/xctest-documentation/
//
//
// NOTE ABOUT THESE TESTS
//
// Tests are setup to be full 'end to end' tests hitting a real server
// These tests should be run against a copy of the most recent
// Oddworks server using the NASA data
//
// https://github.com/oddnetworks/oddworks
// 
// specifically https://github.com/oddnetworks/oddworks/commit/33d14cbd5da6ae8c63ab86332262a8c22a2046d7
// is required to fix prior issues with included objects in api requests
// this commit will also include updated test data
//

import XCTest
@testable import OddSDK

protocol Idable {
  var id: String? { get set }
}

extension Set where Element : Idable {
  func containsObjectWithId(_ id: String) -> Bool {
    var result = false
    for (entity) in self {
      if let entityId = entity.id {
        if entityId == id {
          result = true
          break
        }
      }
    }
    return result
  }
}

extension OddMediaObject : Idable {}

class OddSDKTests: XCTestCase {
  
  let EXPECTATION_WAIT : TimeInterval = 10
  
  func configureSDK() {
    OddContentStore.sharedStore.API.serverMode = .local
    
    OddLogger.logLevel = .info
    
    /*
     If you are running your own Oddworks server the server will provide tokens for each channel
     and device you have configured when it launches. Paste the apple-tv token below.
     
     If you are using an Oddworks hosted server the token will be provided for you.
     
     This line is required to allow access to the API. Once you have entered your authToken uncomment
     to continue
     */
    OddContentStore.sharedStore.API.authToken = "<your auth token>"
  }
  
  override func setUp() {
    super.setUp()
    configureSDK()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
    OddContentStore.sharedStore.resetStore()
  }
  
  
  func testCanFetchConfig() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { return }
        XCTAssertNotNil(config, "SDK should load config")
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        okExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testConfigHasCorrectViews() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { return }
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        XCTAssertEqual(config.idForViewName("homepage"), "homepage", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("splash"), "splash", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("menu"), "menu", "Config should have the correct views")
        okExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCanLoadHomeView() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          XCTAssertNotNil(view, "SDK should load a view")
          XCTAssertEqual(view.id, "homepage", "Config should have correct home view id")
          XCTAssertEqual(view.title, "Nasa Sample Homepage", "Config should have correct home view title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testViewHasCorrectRelationships() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          
          if let node = view.relationshipNodeWithName("promotion") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            if let promo = node.relationship as? OddRelationship {
              XCTAssertNotNil(promo, "View should have a relationship for promotion")
              XCTAssertEqual(promo.id, "daily-show", "View should have promotion relationship with correct id")
              XCTAssertEqual(promo.mediaObjectType.toString(), "promotion", "View should have promotion relationship with correct type")

            }
          }

          if let node = view.relationshipNodeWithName("featuredMedia") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            if let featuredMedia = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredMedia, "View should have a relationship for featuredMedia")
              XCTAssertEqual(featuredMedia.id, "0db5528d4c3c7ae4d5f24cce1c9fae51", "View should have featuredMedia relationship with correct id")
              XCTAssertEqual(featuredMedia.mediaObjectType.toString(), "video", "View should have featuredMedia relationship with correct type")
            }
          }

          if let node = view.relationshipNodeWithName("featuredCollections") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            XCTAssertNil(node.multiple, "View should only have singular relationships" )
            if let featuredCollections = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredCollections, "View should have a relationship for featuredCollections")
              XCTAssertEqual(featuredCollections.id, "51c12f4b70ff4a70925a1be26b8442af", "View should have featuredCollections relationship with correct id")
              XCTAssertEqual(featuredCollections.mediaObjectType.toString(), "collection", "View should have featuredCollections relationship with correct type")
            }
          }

          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
  
  func testViewFetchesIncludedObjects() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: "featuredMedia,featuredCollections", callback: { (objects, errors) in
          
          let cache = OddContentStore.sharedStore.mediaObjects
          XCTAssertEqual(cache.count, 3, "Loading a view should build included objects")
          
          XCTAssertTrue(cache.containsObjectWithId("homepage"), "Lodaing a view should build the view and included objects")
          XCTAssertTrue(cache.containsObjectWithId("0db5528d4c3c7ae4d5f24cce1c9fae51"), "Lodaing a view should build the view and included objects")
          XCTAssertTrue(cache.containsObjectWithId("51c12f4b70ff4a70925a1be26b8442af"), "Lodaing a view should build the view and included objects")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
  func testCollectionsHaveCorrectRelationships() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
          guard let collection = objects.first as? OddMediaObjectCollection else { return }
          
          if let node = collection.relationshipNodeWithName("entities") {
            XCTAssertEqual(node.numberOfRelationships, 6, "Collection should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 6, "Collections relationship node should return the correct number of ids")
            if let videos = node.relationship as? Array<OddRelationship> {
              XCTAssertEqual(videos.count, 6, "Collection relationship should have an array of entities")
              XCTAssertEqual(videos.first?.id, "b99ab89d33c654277b739dadc53a2822", "Collection should have to correct related entities")
              XCTAssertEqual(videos.last?.id, "943af21ce037461b77c1752073c0a2a1", "Collection should have to correct related entities")
            }
          }
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
    XCTAssertNil(error, "Error")
    })
  }
  
  func testCollectionsFetchIncludedObjects() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
          guard let collection = objects.first as? OddMediaObjectCollection else { return }
          
          let cache = OddContentStore.sharedStore.mediaObjects
          XCTAssertEqual(cache.count, 7, "Loading a collection should build included objects")
          
          XCTAssertTrue(cache.containsObjectWithId("ab2d92ee98b6309299e92024a487d4c0"), "Loading a view should build the view and included objects")
          guard let node = collection.relationshipNodeWithName("entities"),
            let entities = node.relationship as? Array<OddRelationship> else  { return }
          
          entities.forEach({ (mediaObject) in
            XCTAssertTrue(cache.containsObjectWithId(mediaObject.id), "Loading a view should build the view and included objects")
          })
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testContentStoreLaunchesWithEmptyCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        
        okExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  
  func testFetchedObjectIsAddedToCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let cachedView = OddContentStore.sharedStore.mediaObjects.first as? OddView else { return }
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "After fetching a media object it is added to the content store cache")
          XCTAssertEqual(view.id, cachedView.id, "After fetching a media object the correct object is in the content store cache")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchReturnsResults() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("earth", onResults: { (videos, collections) in
          
          XCTAssertEqual(videos?.count, 4, "Search should return the correct number of video results")
          XCTAssertEqual(collections?.count, 1, "Search should return the correct number of collections results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchResultsAreAddedToStoreCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("space", onResults: { (videos, collections) in
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 10, "Search should return the correct number of video results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenNotCached() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo else { return }
          XCTAssertNotNil(video, "SDK should load a video")
          XCTAssertEqual(video.id, "42baaa6e1e9ce2bb6d96d53007656f02", "Loaded video should have correct id")
          XCTAssertEqual(video.title, "What's Up - April 2016", "Loaded video should have correct title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenCached() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo,
            let cachedVideo = OddContentStore.sharedStore.mediaObjects.first as? OddVideo else { return }
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "Fetched Video should be cached")
          XCTAssertEqual(video.id, cachedVideo.id, "The correct video should be cached")
          
          // now fetch again
          OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
            guard let video = objects.first as? OddVideo else { return }
            XCTAssertEqual(objects.count, 1, "Fetching from cache returns the correct number of objects")
            XCTAssertEqual(video.id, cachedVideo.id, "Fetching from cache returns the correct video")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testVideoHasCorrectData() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo else { return }
          XCTAssertNotNil(video, "SDK should load a video")
          XCTAssertEqual(video.id, "42baaa6e1e9ce2bb6d96d53007656f02", "Video should have correct id")
          XCTAssertEqual(video.title, "What's Up - April 2016", "Video should have correct title")
          XCTAssertEqual(video.notes, "<p><a href='http://www.podtrac.com/pts/redirect.m4v/www.jpl.nasa.gov/videos/whatsup/20160401/JPL-20160401-WHATSUf-0001-720-CC.m4v'>\r\n<img src='http://www.jpl.nasa.gov/multimedia/thumbs/whatsup20140701-226.jpg' align='left' alt='' width='100' height='75' border='0' /></a><br />\r\n<br />\r\nJupiter, Mars, the Lyrid meteor shower and 2016�s best views of Mercury. </p><br clear='all'/><br />", "Video should have the correct description")
          XCTAssertEqual(video.urlString, "http://www.podtrac.com/pts/redirect.m4v/www.jpl.nasa.gov/videos/whatsup/20160401/JPL-20160401-WHATSUf-0001-720-CC.m4v", "Video should have correct url")
          XCTAssertEqual(video.duration, 13000000, "Video should have correct duration")
          XCTAssertEqual(video.thumbnailLink, "http://image.oddworks.io/NASA/space4.jpeg", "Video should have correct image link")
          XCTAssertNotNil(video.cacheTime, "Video should have a cacheTime value")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testFetchReturnsOnlyRequestedObjectTypesNoInclude() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let menuViewId = config.idForViewName("menu") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [menuViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.allIds else { return }
          
          OddContentStore.sharedStore.objectsOfType(.collection, ids: ids, include: nil, callback: { (objects, errors) in
            XCTAssertEqual(objects.count, 1, "Fetch objects of type should only return the correct types")
            XCTAssertEqual(objects.first?.id, "ab2d92ee98b6309299e92024a487d4c0", "Fetch objects of type should only return the correct types")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })

  }

  
  func testFetchReturnsOnlyRequestedObjectTypesWithInclude() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let menuViewId = config.idForViewName("menu") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [menuViewId], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.allIds else { return }
          
          OddContentStore.sharedStore.objectsOfType(.collection, ids: ids, include: nil, callback: { (objects, errors) in
            XCTAssertEqual(objects.count, 1, "Fetch objects of type should only return the correct types")
            XCTAssertEqual(objects.first?.id, "ab2d92ee98b6309299e92024a487d4c0", "Fetch objects of type should only return the correct types")
            XCTAssertEqual(errors!.first?.userInfo["error"]! as? String, "0db5528d4c3c7ae4d5f24cce1c9fae51 exists but is not of type collection", "Fetch objects of type should return an error for mismatched types")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
    
  }
  
  func testCanFetchNodeIdsOfType() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.objectsOfType(.view, ids: ["menu"], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.idsOfType(.video) else { return }
          XCTAssertEqual(ids.count, 1)
          XCTAssertEqual(ids[0], "0db5528d4c3c7ae4d5f24cce1c9fae51")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCanFetchObjectsInRelationship() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.objectsOfType(.view, ids: ["menu"], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items") else { return }
          node.getAllObjects({ (objects, errors) in
            XCTAssertEqual(objects.count, 2)
            XCTAssertEqual(objects.filter({$0.id == "0db5528d4c3c7ae4d5f24cce1c9fae51"}).count, 1)
            XCTAssertEqual(objects.filter({$0.id == "ab2d92ee98b6309299e92024a487d4c0"}).count, 1)
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
}