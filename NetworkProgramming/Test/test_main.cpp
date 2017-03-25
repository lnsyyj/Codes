#include "../Base/Mutex.h"



int main(){

	MutexLock mutexlock;
	MutexLockGuard mutexlockguard(&mutexlock);

	return 0;
}