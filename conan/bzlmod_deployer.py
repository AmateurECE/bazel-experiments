from conan.tools.files import copy
import os


def deploy(graph, output_folder, **kwargs):
    conanfile = graph.root.conanfile
    for dep in conanfile.dependencies.values():
        new_folder = os.path.join(output_folder, dep.ref.name)
        copy(conanfile, "*", dep.package_folder, new_folder)
        dep.set_deploy_folder(new_folder)
