CC -O1  -Xcompiler -fPIC --debug -I.. -Isubmodule/include -Isubmodule/build -Isubmodule/build/acc-runtime/api -g -G -lm   -shared -o astaroth_sgl.so libgpu_astaroth.a libload_store.a  -L submodule/build/src/core -L submodule/build/src/core/kernels -L submodule/build/src/utils -lastaroth_core -lkernels -lastaroth_utils -Isubmodule/include
