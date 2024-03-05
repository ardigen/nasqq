
/*
 * Extract name of software tool from process name using $task.process
 */
def getSoftwareName(task_process) {
    return task_process.tokenize(':')[-1].toLowerCase()
}

/*
 * Function to initialise default values and to generate a Groovy Map of available options for nf-core modules
 */
def initOptions(Map args) {
    def Map options = [:]
    options.args          = args.args ?: ''
    options.args2         = args.args2 ?: ''
    options.publish_by_id = args.publish_by_id ?: false
    options.publish_dir   = args.publish_dir ?: ''
    options.publish_files = args.publish_files
    options.suffix        = args.suffix ?: ''
    return options
}

/*
 * Tidy up and join elements of a list to return a path string
 */
def getPathFromList(path_list) {
    def paths = path_list.findAll { item -> !item?.trim().isEmpty() }  // Remove empty entries
    paths = paths.collect { it.trim().replaceAll("^[/]+|[/]+\$", "") } // Trim whitespace and trailing slashes
    return paths.join('/')
}

/*
 * Function to save/publish module results
 */
def saveFiles(Map args) {
    if (!args.filename.endsWith('.version.yml')) {
        def ioptions = initOptions(args.options)
        def path_list = [ ioptions.publish_dir ?: args.publish_dir ]
        if (ioptions.publish_by_id) {
            path_list.add(0, args.publish_id)
        }
        if (ioptions.publish_files instanceof Map) {
            for (ext in ioptions.publish_files) {
                if (args.filename.endsWith(ext.key)) {
                    def ext_list = path_list.collect()
                    ext_list.add(ext.value)
                    return "${getPathFromList(ext_list)}/$args.filename"
                }
            }
        } else if (ioptions.publish_files == null) {
            return "${getPathFromList(path_list)}/$args.filename"
        }
    }
}

//Helpers --------------------------------------------
def absoluteFilePath(manifestPath, filePath) {
    f = new File(filePath)
    if (f.isAbsolute()){
        return f.getPath()
    }
    parent = new File(manifestPath).parent
    if (parent){
        new File(parent, filePath).getAbsolutePath()
    } else {
        f.getAbsolutePath()
    }
}

def absolutePathChecked(manifestPath, filePath) {
    absPath = absoluteFilePath(manifestPath, filePath)
    if (! new File(absPath).exists()){
        throw new Exception("File $absPath does not exist, please check your manifest file")
    }
    absPath
}

def getReferenceDir(reference) {
    new File("${reference}").getParent()
}
