Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "SwiftVideoPlayer"
s.summary = "SwiftVideoPlayer is a lightweight customisable video Player written in swift above AVPlayer."
s.requires_arc = true

# 2
s.version = "1.0.0"


# 3
s.license = { :type => "MIT", :file => "LICENSE" }


# 4
s.author = { "Benjamin Horner" => "b.e.horner@gmail.com" }


# 5
s.homepage = "https://github.com/benjaminhorner/SwiftVideoPlayer"


# 6
s.source = { :git => "https://github.com/benjaminhorner/SwiftVideoPlayer.git", :tag => "#{s.version}"}


# 7
s.source_files = "SwiftVideoPlayer/**/*.{swift}"

end
