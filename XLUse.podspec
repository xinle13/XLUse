Pod::Spec.new do |s|
    s.name         = 'XLUse'
    s.version      = '1.0.0'
    s.summary      = 'xinle first use'
    s.homepage     = 'https://github.com/xinle13/XLUse'
    s.license      = 'MIT'
    s.authors      = {'xinle13' => '1170954909@qq.com'}
    s.platform     = :ios, '8.0'
    s.source       = {:git => 'https://github.com/xinle13/XLUse.git', :tag => s.version}
    s.source_files = 'XLUse/**/*.{h,m}'
    s.resource     = 'XLUse/XLUse.bundle'
    s.requires_arc = true
end