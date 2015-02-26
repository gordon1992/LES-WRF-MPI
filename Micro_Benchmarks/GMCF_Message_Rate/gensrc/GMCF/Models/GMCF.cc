// Generated wrapper for GMCF. Only parameter is $nmodels
#include "GMCF.h"
#include "CastPointers.h"
#include "GMCFmodelF.h"

 
int64_t GMCF::run_model1(SBA::System* sba_sysptr, SBA::Tile* sba_tileptr, uint64_t model_id) {
#ifdef VERBOSE
	std::cout << "INSIDE run_model1" << std::endl;
#endif
	int model = (int)model_id;

    // Cast void* to int64_t
    // We need to cast to int64_t and then pass the address rather than casting to uint64_t* I think
#ifdef VERBOSE
	std::cout << "CHECKING pointers for MODEL 1: .tdc file name:" << sba_sysptr->task_description << "; Tile address: "<< sba_tileptr->address << std::endl;
#endif

#ifdef VERBOSE
	std::cout << "\n CASTING System pointer in model 1\n";

#endif
    // Here we can get the thread id and link the model id to it
    uint64_t th_id = (uint64_t)pthread_self();
    sba_sysptr->model_id_from_thread_id[th_id]=model_id;
	void* sys_vp = reinterpret_cast<void*>(sba_sysptr);
	int64_t sys_iv = (int64_t)sys_vp;
	int64_t* sba_sys_ivp = &sys_iv;
#ifdef VERBOSE
	std::cout << "\n CASTING Tile pointer\n";
#endif
	void* tile_vp = reinterpret_cast<void*>(sba_tileptr);
	int64_t tile_iv = (int64_t)tile_vp;
    int64_t* sba_tile_ivp = &tile_iv;
    // We can now also store sba_sys_ivp and sba_tile_ivp in the gmcfAPI module
    // We could store sba_sys_vp, not ivp
    // But that would mean *all* Fortran subroutines need type(c_ptr)
    // gmcfinitsys(sba_sys_ivp)
    // gmcfinittile(&model,sba_tile_ivp); 
#ifdef VERBOSE
	std::cout << "CALLING Fortran program_message_rate_" << std::endl;
#endif

    // Here we call the actual Fortran function
    program_message_rate_(sba_sys_ivp,sba_tile_ivp,&model);

#ifdef VERBOSE
	std::cout << "LEAVING run_model1" << std::endl;
#endif

    return 1; // purely for GPRM compatibility!
}		
