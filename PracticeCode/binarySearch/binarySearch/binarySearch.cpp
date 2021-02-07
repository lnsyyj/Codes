// binarySearch.cpp : 此文件包含 "main" 函数。程序执行将在此处开始并结束。
//

#include <iostream>
using namespace std;

// key为要找的数字，arr为数字数组，n为数组元素个数
int binarySearch(int arr[], int n, int key)
{
    int low = 0;
    int high = n - 1;
    while (low <= high) {
        int midIndex = (low + high) / 2;
        int midVal = arr[midIndex];
        if (midVal < key) {
            low = midIndex + 1;
        }else if (midVal > key) {
            high = midIndex - 1;
        }else
        {
            return midIndex;
        }
    }
    return -1;
}

int main()
{
    int result = -1;
    int bufferArr[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    result = binarySearch(bufferArr, 10, 5);
    if (result == -1) {
        cout << "not find" << endl;
    }else {
        cout << "find" << endl;
    }
}

// 运行程序: Ctrl + F5 或调试 >“开始执行(不调试)”菜单
// 调试程序: F5 或调试 >“开始调试”菜单

// 入门使用技巧: 
//   1. 使用解决方案资源管理器窗口添加/管理文件
//   2. 使用团队资源管理器窗口连接到源代码管理
//   3. 使用输出窗口查看生成输出和其他消息
//   4. 使用错误列表窗口查看错误
//   5. 转到“项目”>“添加新项”以创建新的代码文件，或转到“项目”>“添加现有项”以将现有代码文件添加到项目
//   6. 将来，若要再次打开此项目，请转到“文件”>“打开”>“项目”并选择 .sln 文件
