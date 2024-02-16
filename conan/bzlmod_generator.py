from conan.tools.files import save
import os
import glob


def find_first_file_in_path_list(filename, paths):
    """Find the first instance of a filename in the list of paths"""
    for path in paths:
        for item in glob.glob(path + "/**/*", recursive=True):
            if os.path.basename(item) == filename:
                return item
    return None


def relativize_path(root, path):
    if not root.endswith('/'):
        root = root + '/'
    if path.startswith(root):
        return path.removeprefix(root)
    return path


def stringify(item):
    return "\"" + item + "\""


def local_target(name):
    return ":" + name


class Component:
    def __init__(self, package_folder, name, cpp_info):
        self.folder = package_folder
        self.name = name
        self.cpp_info = cpp_info

    def generate_bazel(self):
        libnames = [stringify(local_target(self.libname(lib)))
                    for lib in self.cpp_info.libs]
        libs = [self.cc_import_lib(lib) for lib in self.cpp_info.libs]
        if self.cpp_info.objects:
            libs.append(self.cc_import_objects(self.name,
                                               self.cpp_info.objects))
            libnames.append(stringify(
                local_target(self.objectname(self.name))))
        document = "\n".join(libs)
        return document + "\n" + self.cc_library(libnames)

    def libname(self, lib):
        """Return a Bazel target name for a cc_import given its library name
        (e.g., the name passed to pkg-config --libs)"""
        return f'lib{lib}'

    def objectname(self, lib):
        """Return the name of the object library generated for this
        component."""
        return f'{lib}_obj'

    def find_headers(self):
        headers = []
        for d in self.cpp_info.includedirs:
            for h in glob.glob(d + "**/*.h") + glob.glob(d + "**/*.hpp"):
                headers.append(
                    stringify(
                        relativize_path(self.folder, h)))
        return headers

    def cc_library(self, libs):
        return (
            "cc_library(\n"
            f"    name = {stringify(self.name)},\n"
            f"    deps = [{','.join(libs)}],\n"
            f"    hdrs = [{','.join(self.find_headers())}],\n"
            "    visibility = [\"//visibility:public\"],\n"
            ")\n"
        )

    def cc_import_lib(self, lib):
        path = find_first_file_in_path_list(
            f'lib{lib}.a', self.cpp_info.libdirs)
        library_type = "static"
        if not path:
            path = find_first_file_in_path_list(
                f'lib{lib}.so', self.cpp_info.libdirs)
            library_type = "shared"
        if not path:
            return ""

        path = relativize_path(self.folder, path)
        return (
            "cc_import(\n"
            f"    name = {stringify(self.libname(lib))},\n"
            f"    {library_type}_library = {stringify(path)},\n"
            ")\n"
        )

    def cc_import_objects(self, lib, objects):
        object_files = ",".join([stringify(relativize_path(self.folder, o))
                                for o in objects])
        return (
            "cc_library(\n"
            f"    name = {stringify(self.objectname(lib))},\n"
            "    alwayslink = True,\n"
            f"    srcs = [{object_files}],\n"
            ")\n"
        )


class Bzlmod:
    def __init__(self, conanfile):
        self._conanfile = conanfile

    def generate(self):
        for dep in self._conanfile.dependencies.values():
            save(self._conanfile,
                 f'{dep.ref.name}/BUILD.bazel',
                 self.bzlmod_build(dep))

    def bzlmod_build(self, dep):
        # TODO: Generating root target?
        # document = component_object(cpp_info)
        document = ""
        for name, component in dep.cpp_info.components.items():
            target = Component(dep.package_folder, name, component)
            document = document + target.generate_bazel() + "\n"
        return document
