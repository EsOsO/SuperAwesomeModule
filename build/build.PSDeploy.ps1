Deploy Module {
    By PSGalleryModule {
        Tagged Release
        FromSource $ModuleToPublish
        To PSGallery
        WithOptions @{
            ApiKey = $ENV:NugetApiKey
        }
    }
}
