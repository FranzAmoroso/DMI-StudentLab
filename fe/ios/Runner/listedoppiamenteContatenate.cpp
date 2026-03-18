#include <iostream>

using namespace std;

template <typename T> struct Node {
    T dato;
    Node* next;
    Node* prev;
    Node(T _dato):dato(_dato),next(nullptr),prev(nullptr){}
};


template <typename T> 
class DoublyList {
    public:
        DoublyList(): head(nullptr){}
        ~DoublyList(){
            while(head){
                Node<T>* tmp=head;
                head=head->next;
                delete tmp;
            }
        }

        DoublyList<T>& Insert(T dato){
            Node<T>* newNode= new Node(dato);
            if(!head || dato < head->dato){
                newNode->next = head;
                if(head) head->prev = newNode;
                head=newNode;
                return *this;
            }

            Node<T>* curr=head;
            while(curr->next && dato > curr->next->dato) curr = curr->next;
            newNode->next = curr->next;
            newNode->prev= curr;
            if(curr->next) curr->next->prev = newNode;
            curr->next=newNode;
            return *this;
        }

        Node<T>* Search(T dato){
            Node<T>* tmp=head;
            if(!head) cout << "Stack undeflow." << endl;
            if(head->dato == dato) cout < "Risultato della ricerca:\n" << dato << endl;
            Node<T>* curr= head;
            while(curr && curr->dato < dato) curr = curr->next;
            cout << "Risultato della ricerca:" << endl; 
            if(curr->dato == dato) return curr->dato;
            cout << dato << " not founded." << endl;
        }

        void Print() const {
            Node<T>* tmp =head;
            cout  << "Lista: ";
            while(tmp){
                cout << "[" << tmp->dato << "] -> "; 
                tmp = tmp->next;
            }
            cout << "nullptr" << endl;
        }
        bool Remove(T dato){
            if(head && head->dato == dato) {
                head->prev->next = head->next;
                if(head->next) head->next->prev = head->prev;
                return true;
            }
            Node<T>* tmp = head;
            while(tmp && tmp->dato < dato) tmp = tmp->next;
            if(tmp->dato == dato) {
                tmp->prev =tmp->next;
                if(tmp->next) tmp->next->prev = tmp->prev;
                return true;
            }
            return false;
        }
    private:
        Node<T>* head;
};

int main(){
    DoublyList<int> l;
    cout << "\n\\_+_/\n" << endl;
    l.Print();
    l.Insert(20);
    l.Print();
    l.Insert(189);
    l.Print();

    cout << "\n~o~\n" << endl;
    return 0;
}
