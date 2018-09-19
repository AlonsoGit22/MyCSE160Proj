/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"


module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

    /*include all the processes from the lab proj 1 slide */
uses interface NeighborQueueListC<uint16_t> as NeighborQueueList;
uses interface PoolC<uint16_t> as NeighborPool;
uses interface TimerMilliC as NodeTimer;
uses interface RandomC as Random;
uses interface AMSenderC as Sender;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

/* M make sequence counter */
uint16_t sequenceCount = 1;
unit16_t sequence = 0;
uint16_t replysequence = 0;

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;

    /* new code  seeing if the TTL is 0 if it is drop the packet*/
if (myMsg -> TTL == 0){
return msg;
}
elseif (myMsg -> TTL != 0 && myMsg ->protocol == PROTOCOL_PING) {

if (myMsg->protocol == Protocol_PING){
dbg(GENERAL_CHANNEL, "Recived Packet From Node: %d at Node : %d\n\n", myMsg->src,TOS_NODE_ID);
dbg(FLOODING_CHANNEL, "Packet recieved at Node: %d and Mmeant or Node: %d\n\n", TOS_NODE_ID, myMsg->dest);
}

}
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }
/* add to Queue List */
call NeighborQueueList.pushback(myMsg);
/*checking if the msg has gotten to the correct destination */
if(TOS_NODE_ID == myMsg->dest) {
dbg(FLOODING_CHANNEL, "Packet has arrived at destination: %d from %d \n\n", myMsg->dest, myMsg-src);

}
/*If the packat is not a repeat */
elseif(TOS_NODE_ID != myMsg-> && myMsg->protocol == PROTOOL_PING){

/* Foward a new paket to the next node */

makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL -1, PROTOCOL_PING,sequence,(uint8_t)payload,sizeof(myMsg->payload));
call Sender.send(replyPackage,AM_BROADCAST_ADDR);

}


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
