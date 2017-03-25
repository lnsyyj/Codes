#ifndef MUTEX_LOCK_H
#define MUTEX_LOCK_H

#include <pthread.h>

class MutexLock{
//
public:
	MutexLock(){}
	~MutexLock(){}

	void lock();
	void unlock();

//don't allow copying
private:
	MutexLock(const MutexLock& func_mutex);
	MutexLock& operator= (const MutexLock& func_mutex);
//
private:
	pthread_mutex_t m_mutex;
};



class MutexLockGuard{
public:
	explicit MutexLockGuard(MutexLock& mutexlock):m_mutexlock(mutexlock){
		m_mutexlock.lock();
	}

	~MutexLockGuard(){
		m_mutexlock.unlock();
	}

private:
	MutexLock m_mutexlock;
};


#endif