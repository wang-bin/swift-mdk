Pod::Spec.new do |s|
    s.name              = 'swift-mdk'
    s.version           = '0.32.0'
    s.summary           = 'Multimedia Development Kit'
    s.homepage          = 'https://github.com/wang-bin/swift-mdk'

    s.author            = { 'Wang Bin' => 'wbsecg1@gmail.com' }
    s.license           = { :type => 'MIT', :text => <<-LICENSE
    Copyright 2024 WangBin
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  LICENSE
        }

    s.platform          = :osx, :ios, :tvos, :visionos
    s.osx.deployment_target = '10.13'
    s.ios.deployment_target = '12.0'
    s.tvos.deployment_target = '12.0'
    s.visionos.deployment_target = '1.0'
    s.source            = { :git => 'https://github.com/wang-bin/swift-mdk.git' }
    s.source_files      = 'Sources/swift-mdk/*.swift'
    s.dependency        'mdk'
end
